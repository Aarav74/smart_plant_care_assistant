#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <WiFi.h>
#include <WebServer.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

// OLED Display Settings
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDR 0x3C
#define OLED_SDA 21  // GPIO21
#define OLED_SCL 22  // GPIO22

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// Sensor Pins
const int soilPin = 36;    // GPIO36 (Analog VP) - Soil Sensor
const int ldrPin = 39;     // GPIO39 (Analog VN) - LDR Module A0 pin
const int mq2Pin = 34;     // GPIO34 (Analog) - MQ-2 Gas Sensor

// Sensor calibration values - ADJUST THESE FOR YOUR SENSORS
int drySoilValue = 4095;   // Value when sensor is dry (in air)
int wetSoilValue = 1500;   // Value when sensor is in water
int darkLightValue = 500;  // Value in complete darkness
int brightLightValue = 3000; // Value in bright light

// MQ-2 Calibration (adjust based on your environment)
int cleanAirValue = 100;   // Value in clean air (calibrate this)
int smokeThreshold = 300;  // Threshold for smoke detection
int gasThreshold = 400;    // Threshold for harmful gas detection

// Thresholds (calculated from calibration)
int drySoilThreshold;
int darkLightThreshold;
int brightLightThreshold;

// WiFi Settings
const char* ssid = "Airtel_404notfound";
const char* password = "Jp@05051976";

// WebServer on port 80
WebServer server(80);

// WebSocket server on port 81
WebSocketsServer webSocket = WebSocketsServer(81);

// Timing variables
unsigned long lastSensorRead = 0;
unsigned long sensorInterval = 2000; // Read sensors every 2 seconds
unsigned long lastWebSocketSend = 0;
unsigned long webSocketInterval = 1000; // Send data every 1 second

// Sensor data
int currentSoilValue = 0;
int currentLightValue = 0;
int currentMQ2Value = 0;
String currentStatus = "Starting...";
String airQualityStatus = "Air Quality: Good";

// HTML page for testing
const char* htmlPage = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <title>ESP32 Plant & Air Monitor</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; text-align: center; margin: 40px; }
    .status { font-size: 24px; font-weight: bold; margin: 20px; padding: 10px; border-radius: 5px; }
    .happy { background-color: #d4edda; color: #155724; }
    .sad { background-color: #f8d7da; color: #721c24; }
    .sleepy { background-color: #e2e3e5; color: #383d41; }
    .hot { background-color: #fff3cd; color: #856404; }
    .air-good { background-color: #d4edda; color: #155724; }
    .air-warning { background-color: #fff3cd; color: #856404; }
    .air-danger { background-color: #f8d7da; color: #721c24; }
    .data { display: flex; justify-content: space-around; margin: 20px; flex-wrap: wrap; }
    .data-item { background: #f8f9fa; padding: 15px; border-radius: 5px; width: 45%; margin: 5px; }
    .connection { padding: 10px; margin: 10px; border-radius: 5px; }
    .connected { background-color: #d4edda; color: #155724; }
    .disconnected { background-color: #f8d7da; color: #721c24; }
    .alert { background-color: #ffcccc; color: #cc0000; padding: 10px; margin: 10px; border-radius: 5px; }
  </style>
</head>
<body>
  <h1>ESP32 Plant & Air Quality Monitor</h1>
  <div id="connection" class="connection disconnected">Disconnected</div>
  <div id="status" class="status">Connecting...</div>
  <div id="airStatus" class="status air-good">Air Quality: Good</div>
  
  <div class="data">
    <div class="data-item">
      <h3>Soil Moisture</h3>
      <div id="soilValue">--</div>
    </div>
    <div class="data-item">
      <h3>Light Level</h3>
      <div id="lightValue">--</div>
    </div>
    <div class="data-item">
      <h3>Air Quality</h3>
      <div id="airValue">--</div>
    </div>
    <div class="data-item">
      <h3>Gas Level</h3>
      <div id="gasLevel">--</div>
    </div>
  </div>
  
  <div id="alertBox" class="alert" style="display: none;">
    Air Quality Alert! Please check environment.
  </div>
  
  <div>
    <button onclick="reconnectWS()">Reconnect</button>
    <button onclick="calibrateMQ2()">Calibrate MQ-2 (Clean Air)</button>
  </div>
  
  <script>
    var ws = null;
    var reconnectInterval = null;
    
    function connectWS() {
      try {
        ws = new WebSocket('ws://' + window.location.hostname + ':81/');
        
        ws.onopen = function() {
          console.log('WebSocket connection established');
          document.getElementById('connection').textContent = 'Connected';
          document.getElementById('connection').className = 'connection connected';
          if (reconnectInterval) {
            clearInterval(reconnectInterval);
            reconnectInterval = null;
          }
        };
        
        ws.onmessage = function(event) {
          try {
            var data = JSON.parse(event.data);
            document.getElementById('soilValue').textContent = data.soil;
            document.getElementById('lightValue').textContent = data.light;
            document.getElementById('airValue').textContent = data.air_quality;
            document.getElementById('gasLevel').textContent = data.gas_level + ' ppm';
            
            var statusEl = document.getElementById('status');
            statusEl.textContent = data.status;
            
            // Update status color based on plant status
            statusEl.className = 'status ';
            if (data.status.includes('happy')) statusEl.className += 'happy';
            else if (data.status.includes('Water')) statusEl.className += 'sad';
            else if (data.status.includes('dark')) statusEl.className += 'sleepy';
            else if (data.status.includes('bright')) statusEl.className += 'hot';
            
            // Update air quality status
            var airStatusEl = document.getElementById('airStatus');
            airStatusEl.textContent = data.air_quality_status;
            
            airStatusEl.className = 'status ';
            if (data.air_quality_status.includes('Good')) airStatusEl.className += 'air-good';
            else if (data.air_quality_status.includes('Warning')) airStatusEl.className += 'air-warning';
            else if (data.air_quality_status.includes('Danger')) airStatusEl.className += 'air-danger';
            
            // Show/hide alert
            var alertBox = document.getElementById('alertBox');
            if (data.air_quality_status.includes('Danger') || data.air_quality_status.includes('Warning')) {
              alertBox.style.display = 'block';
            } else {
              alertBox.style.display = 'none';
            }
            
          } catch (e) {
            console.error('Error parsing data:', e);
          }
        };
        
        ws.onclose = function() {
          console.log('WebSocket connection closed');
          document.getElementById('connection').textContent = 'Disconnected';
          document.getElementById('connection').className = 'connection disconnected';
          
          // Auto-reconnect after 3 seconds
          if (!reconnectInterval) {
            reconnectInterval = setInterval(function() {
              console.log('Attempting to reconnect...');
              connectWS();
            }, 3000);
          }
        };
        
        ws.onerror = function(error) {
          console.log('WebSocket error:', error);
          document.getElementById('connection').textContent = 'Error';
          document.getElementById('connection').className = 'connection disconnected';
        };
        
      } catch (e) {
        console.error('Error creating WebSocket:', e);
      }
    }
    
    function reconnectWS() {
      if (ws) {
        ws.close();
      }
      if (reconnectInterval) {
        clearInterval(reconnectInterval);
        reconnectInterval = null;
      }
      setTimeout(connectWS, 100);
    }
    
    function calibrateMQ2() {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send('calibrate_mq2');
        alert('Calibration command sent. Ensure sensor is in clean air.');
      } else {
        alert('WebSocket not connected. Please connect first.');
      }
    }
    
    // Initial connection
    connectWS();
  </script>
</body>
</html>
)rawliteral";

void setup() {
  Serial.begin(115200);
  
  // Initialize I2C with custom pins
  Wire.begin(OLED_SDA, OLED_SCL);
  
  // Initialize OLED
  if(!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("OLED not found!");
    while(1);
  }
  
  // Initialize MQ-2 sensor pin
  pinMode(mq2Pin, INPUT);
  
  // Show startup animation
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0,0);
  display.println("Plant & Air Monitor");
  display.println("Initializing...");
  display.display();
  
  // Print pin assignments to Serial
  Serial.println("Pin Configuration:");
  Serial.println("OLED SDA: GPIO " + String(OLED_SDA));
  Serial.println("OLED SCL: GPIO " + String(OLED_SCL));
  Serial.println("Soil Sensor: GPIO " + String(soilPin));
  Serial.println("LDR Module: GPIO " + String(ldrPin));
  Serial.println("MQ-2 Sensor: GPIO " + String(mq2Pin));
  
  // Calibrate sensors
  calibrateSensors();
  
  // Connect to WiFi
  setupWiFi();
  
  // Start WebServer
  server.on("/", []() {
    server.send(200, "text/html", htmlPage);
  });
  
  // Add calibration endpoints
  server.on("/calibrate", HTTP_GET, []() {
    String html = "<h1>Sensor Calibration</h1>";
    html += "<p>Current Values:</p>";
    html += "<p>Soil: " + String(analogRead(soilPin)) + "</p>";
    html += "<p>Light: " + String(analogRead(ldrPin)) + "</p>";
    html += "<p>MQ-2: " + String(analogRead(mq2Pin)) + "</p>";
    html += "<p><a href='/calibrate/dry'>Calibrate Dry Soil</a></p>";
    html += "<p><a href='/calibrate/wet'>Calibrate Wet Soil</a></p>";
    html += "<p><a href='/calibrate/dark'>Calibrate Dark</a></p>";
    html += "<p><a href='/calibrate/bright'>Calibrate Bright</a></p>";
    html += "<p><a href='/calibrate/mq2'>Calibrate MQ-2 (Clean Air)</a></p>";
    server.send(200, "text/html", html);
  });
  
  server.on("/calibrate/dry", []() {
    drySoilValue = analogRead(soilPin);
    saveCalibration();
    server.send(200, "text/plain", "Dry soil calibrated: " + String(drySoilValue));
  });
  
  server.on("/calibrate/wet", []() {
    wetSoilValue = analogRead(soilPin);
    saveCalibration();
    server.send(200, "text/plain", "Wet soil calibrated: " + String(wetSoilValue));
  });
  
  server.on("/calibrate/dark", []() {
    darkLightValue = analogRead(ldrPin);
    saveCalibration();
    server.send(200, "text/plain", "Dark calibrated: " + String(darkLightValue));
  });
  
  server.on("/calibrate/bright", []() {
    brightLightValue = analogRead(ldrPin);
    saveCalibration();
    server.send(200, "text/plain", "Bright calibrated: " + String(brightLightValue));
  });
  
  server.on("/calibrate/mq2", []() {
    cleanAirValue = analogRead(mq2Pin);
    saveCalibration();
    server.send(200, "text/plain", "MQ-2 calibrated (clean air): " + String(cleanAirValue));
  });
  
  server.begin();
  Serial.println("HTTP server started");
  
  // Start WebSocket server
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  Serial.println("WebSocket server started on port 81");
  
  delay(2000);
}

void calibrateSensors() {
  // Calculate thresholds from calibration values
  drySoilThreshold = (drySoilValue + wetSoilValue) * 0.6; // 60% point between dry and wet
  darkLightThreshold = darkLightValue * 1.2; // 20% above dark value
  brightLightThreshold = brightLightValue * 0.8; // 20% below bright value
  
  Serial.println("Sensor calibration loaded:");
  Serial.println("Dry soil: " + String(drySoilValue));
  Serial.println("Wet soil: " + String(wetSoilValue));
  Serial.println("Dark light: " + String(darkLightValue));
  Serial.println("Bright light: " + String(brightLightValue));
  Serial.println("MQ-2 clean air: " + String(cleanAirValue));
  Serial.println("Dry threshold: " + String(drySoilThreshold));
}

void saveCalibration() {
  // In a real application, you would save these to EEPROM
  // For now, we'll just recalculate thresholds
  calibrateSensors();
}

void setupWiFi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  display.clearDisplay();
  display.setCursor(0,0);
  display.print("Connecting to WiFi");
  display.display();

  int dots = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    display.print(".");
    display.display();
    dots++;
    if (dots > 10) {
      display.clearDisplay();
      display.setCursor(0,0);
      display.print("Connecting to WiFi");
      display.display();
      dots = 0;
    }
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());

  display.clearDisplay();
  display.setCursor(0,0);
  display.println("WiFi connected!");
  display.print("IP: ");
  display.println(WiFi.localIP());
  display.display();
  delay(2000);
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      break;
      
    case WStype_CONNECTED:
      {
        IPAddress ip = webSocket.remoteIP(num);
        Serial.printf("[%u] Connected from %d.%d.%d.%d\n", num, ip[0], ip[1], ip[2], ip[3]);
        
        // Send initial data immediately upon connection
        sendSensorData();
      }
      break;
      
    case WStype_TEXT:
      {
        String message = String((char*)payload);
        Serial.printf("[%u] Received: %s\n", num, message.c_str());
        
        // Handle incoming messages
        if (message == "ping") {
          webSocket.sendTXT(num, "pong");
        } 
        else if (message == "calibrate_mq2") {
          // Calibrate MQ-2 sensor (set current reading as clean air)
          cleanAirValue = analogRead(mq2Pin);
          saveCalibration();
          webSocket.sendTXT(num, "MQ-2 calibrated: " + String(cleanAirValue));
        }
      }
      break;
      
    case WStype_BIN:
      Serial.printf("[%u] Received binary data: %u bytes\n", num, length);
      break;
      
    default:
      break;
  }
}

void readSensors() {
  // Read soil moisture
  int soilValue = analogRead(soilPin);
  static int soilAvg = soilValue;
  soilAvg = (soilAvg * 0.8) + (soilValue * 0.2);
  currentSoilValue = soilAvg;
  
  // Read light level
  int lightValue = analogRead(ldrPin);
  static int lightAvg = lightValue;
  lightAvg = (lightAvg * 0.8) + (lightValue * 0.2);
  currentLightValue = lightAvg;
  
  // Read MQ-2 gas sensor
  int mq2Value = analogRead(mq2Pin);
  static int mq2Avg = mq2Value;
  mq2Avg = (mq2Avg * 0.7) + (mq2Value * 0.3); // Stronger filtering for gas sensor
  currentMQ2Value = mq2Avg;
  
  // Calculate plant status
  currentStatus = getPlantStatus(soilAvg, lightAvg);
  
  // Calculate air quality status
  airQualityStatus = getAirQualityStatus(mq2Avg);
}

String getPlantStatus(int soilValue, int lightValue) {
  if (soilValue > drySoilThreshold) {
    return "Water me!";
  } 
  else if (lightValue < darkLightThreshold) {
    return "Too dark...";
  } 
  else if (lightValue > brightLightThreshold) {
    return "Too bright!";
  } 
  else {
    return "I'm happy!";
  }
}

String getAirQualityStatus(int mq2Value) {
  // Calculate relative gas concentration (simplified)
  int gasConcentration = max(0, mq2Value - cleanAirValue);
  
  if (gasConcentration < smokeThreshold / 2) {
    return "Air Quality: Good";
  } 
  else if (gasConcentration < gasThreshold) {
    return "Air Quality: Warning (Smoke detected)";
  }
  else {
    return "Air Quality: DANGER (Harmful gas)";
  }
}

int calculateGasPPM(int mq2Value) {
  // Simplified PPM calculation (this is approximate)
  // For accurate measurements, you need proper calibration curves
  int gasConcentration = max(0, mq2Value - cleanAirValue);
  
  // Convert to approximate PPM (this is a rough estimation)
  // Real calibration requires specific gas calibration curves
  return map(gasConcentration, 0, 1000, 0, 10000);
}

void sendSensorData() {
  // Create JSON string using ArduinoJson library
  StaticJsonDocument<300> doc;
  doc["soil"] = currentSoilValue;
  doc["light"] = currentLightValue;
  doc["mq2"] = currentMQ2Value;
  doc["gas_level"] = calculateGasPPM(currentMQ2Value);
  doc["status"] = currentStatus;
  doc["air_quality_status"] = airQualityStatus;
  doc["air_quality"] = getAirQualitySimple(currentMQ2Value);
  doc["timestamp"] = millis();
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  // Send to all connected clients
  if (webSocket.connectedClients() > 0) {
    webSocket.broadcastTXT(jsonString);
    Serial.println("Sent: " + jsonString);
  }
}

String getAirQualitySimple(int mq2Value) {
  int gasConcentration = max(0, mq2Value - cleanAirValue);
  
  if (gasConcentration < 50) return "Excellent";
  if (gasConcentration < 100) return "Good";
  if (gasConcentration < 200) return "Fair";
  if (gasConcentration < 300) return "Poor";
  return "Hazardous";
}

void loop() {
  server.handleClient();
  webSocket.loop();
  
  unsigned long currentTime = millis();
  
  // Read sensors at regular intervals
  if (currentTime - lastSensorRead >= sensorInterval) {
    readSensors();
    lastSensorRead = currentTime;
  }
  
  // Send data via WebSocket at regular intervals
  if (currentTime - lastWebSocketSend >= webSocketInterval) {
    if (webSocket.connectedClients() > 0) {
      sendSensorData();
    }
    lastWebSocketSend = currentTime;
  }
  
  // Update OLED display every 2 seconds
  static unsigned long lastDisplayUpdate = 0;
  if (currentTime - lastDisplayUpdate >= 2000) {
    updateDisplay();
    lastDisplayUpdate = currentTime;
  }
  
  // Small delay to prevent watchdog issues
  delay(10);
}

void updateDisplay() {
  display.clearDisplay();
  
  // Display plant status with face
  if (currentStatus == "Water me!") {
    drawSadFace();
  } 
  else if (currentStatus == "Too dark...") {
    drawSleepyFace();
  } 
  else if (currentStatus == "Too bright!") {
    drawHotFace();
  } 
  else {
    drawHappyFace();
  }

  display.setCursor(0, 0);
  display.print(currentStatus);
  
  // Display air quality status
  display.setCursor(0, 10);
  if (airQualityStatus.indexOf("DANGER") >= 0) {
    display.print("AIR DANGER!");
  } else if (airQualityStatus.indexOf("Warning") >= 0) {
    display.print("Air Warning");
  } else {
    display.print("Air Good");
  }

  // Display sensor data
  display.setCursor(0, 54);
  display.print("S:");
  display.print(currentSoilValue);
  display.print(" L:");
  display.print(currentLightValue);
  display.print(" G:");
  display.print(currentMQ2Value);

  display.display();
}

// Emoji Drawing Functions (unchanged)
void drawHappyFace() {
  display.drawCircle(64, 32, 20, WHITE);
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  display.fillCircle(64, 38, 10, WHITE);
  display.fillCircle(64, 36, 10, BLACK);
}

void drawSadFace() {
  display.drawCircle(64, 32, 20, WHITE);
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  display.fillCircle(64, 42, 10, WHITE);
  display.fillCircle(64, 44, 10, BLACK);
}

void drawSleepyFace() {
  display.drawCircle(64, 32, 20, WHITE);
  display.drawLine(52, 26, 60, 26, WHITE);
  display.drawLine(68, 26, 76, 26, WHITE);
  display.drawLine(54, 38, 74, 38, WHITE);
}

void drawHotFace() {
  display.drawCircle(64, 32, 20, WHITE);
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  display.drawLine(54, 38, 74, 38, WHITE);
  display.drawLine(64, 15, 64, 10, WHITE);
  display.drawLine(60, 18, 55, 13, WHITE);
  display.drawLine(68, 18, 73, 13, WHITE);
}
