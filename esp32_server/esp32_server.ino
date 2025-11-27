#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <ESPmDNS.h>

// Display setup
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDR 0x3C
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// WiFi credentials
const char* ssid = "404notfound";
const char* password = "05051976";

// Web server
WebServer server(80);

// DHT sensor for humidity and temperature
#define DHT_PIN 4
#define DHT_TYPE DHT22
DHT dht(DHT_PIN, DHT_TYPE);

// Sensor Pins
const int soilPin = 36;  // GPIO36 (Analog VP)
const int ldrPin = 39;   // GPIO39 (Analog VN)

// Thresholds (Adjust based on your sensors)
const int drySoil = 1500;
const int wetSoil = 800;
const int darkLight = 500;
const int brightLight = 3000;

// Timing variables
unsigned long lastSensorRead = 0;
unsigned long lastDisplayUpdate = 0;
unsigned long lastWiFiCheck = 0;
unsigned long lastIPPrint = 0;
const unsigned long sensorInterval = 2000;    // Read sensors every 2 seconds
const unsigned long displayInterval = 1000;   // Update display every 1 second
const unsigned long wifiCheckInterval = 30000; // Check WiFi every 30 seconds
const unsigned long ipPrintInterval = 60000;   // Print IP every 60 seconds

// Plant status variables
struct PlantData {
  int soilMoisture;
  int lightLevel;
  float temperature;
  float humidity;
  String status;
  String emotion;
  bool isOnline;
  unsigned long lastUpdate;
  int wifiReconnects;
  int sensorErrors;
};

PlantData plantData;

// Function declarations
void showStartupScreen();
void connectToWiFi();
void checkWiFiConnection();
void setupWebServer();
void readSensors();
void updateDisplay();
void updatePlantStatus();
void drawHappyFace();
void drawSadFace();
void drawSleepyFace();
void drawHotFace();
void drawNeutralFace();
void printDebugInfo();
void handleCORS();

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== Smart Plant Monitor v2.1 ===");
  
  // Initialize DHT sensor
  dht.begin();
  Serial.println("DHT sensor initialized");
  
  // Initialize I2C
  Wire.begin();
  Serial.println("I2C initialized");
  
  // Initialize OLED
  if(!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("ERROR: OLED not found!");
    while(1) {
      Serial.println("OLED initialization failed - check connections");
      delay(5000);
    }
  }
  Serial.println("OLED display initialized");
  
  // Show startup screen
  showStartupScreen();
  
  // Connect to WiFi
  connectToWiFi();
  
  // Setup mDNS
  if (!MDNS.begin("plantmonitor")) {
    Serial.println("Error setting up MDNS responder!");
  } else {
    Serial.println("mDNS responder started - accessible at http://plantmonitor.local");
    MDNS.addService("http", "tcp", 80);
  }
  
  // Setup web server routes
  setupWebServer();
  
  // Initialize plant data
  plantData.isOnline = true;
  plantData.lastUpdate = millis();
  plantData.wifiReconnects = 0;
  plantData.sensorErrors = 0;
  
  Serial.println("Setup completed successfully!");
  Serial.println("=================================");
}

void loop() {
  unsigned long currentTime = millis();
  
  // Handle web server requests
  server.handleClient();
  
  // Check WiFi connection periodically
  if (currentTime - lastWiFiCheck >= wifiCheckInterval) {
    checkWiFiConnection();
    lastWiFiCheck = currentTime;
  }
  
  // Read sensors at intervals
  if (currentTime - lastSensorRead >= sensorInterval) {
    readSensors();
    updatePlantStatus();
    lastSensorRead = currentTime;
  }
  
  // Update display at intervals
  if (currentTime - lastDisplayUpdate >= displayInterval) {
    updateDisplay();
    lastDisplayUpdate = currentTime;
  }
  
  // Print IP address periodically for debugging
  if (currentTime - lastIPPrint >= ipPrintInterval) {
    printDebugInfo();
    lastIPPrint = currentTime;
  }
  
  // Small delay to prevent watchdog reset
  delay(50);
}

void connectToWiFi() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0,0);
  display.println("Connecting WiFi...");
  display.println(ssid);
  display.display();
  
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(1000);
    Serial.print(".");
    attempts++;
    
    // Update display with progress
    display.setCursor(0, 24);
    display.print("Attempt: ");
    display.println(attempts);
    display.display();
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("");
    Serial.println("WiFi connected successfully!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal strength (RSSI): ");
    Serial.println(WiFi.RSSI());
    
    display.clearDisplay();
    display.setCursor(0,0);
    display.println("WiFi Connected!");
    display.print("IP: ");
    display.println(WiFi.localIP());
    display.print("RSSI: ");
    display.println(WiFi.RSSI());
    display.display();
    delay(3000);
  } else {
    Serial.println("");
    Serial.println("Failed to connect to WiFi!");
    display.clearDisplay();
    display.setCursor(0,0);
    display.println("WiFi Failed!");
    display.println("Check credentials");
    display.display();
    delay(5000);
  }
}

void checkWiFiConnection() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected! Attempting to reconnect...");
    plantData.wifiReconnects++;
    
    WiFi.begin(ssid, password);
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 10) {
      delay(1000);
      Serial.print(".");
      attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nWiFi reconnected successfully!");
      Serial.print("New IP address: ");
      Serial.println(WiFi.localIP());
    } else {
      Serial.println("\nFailed to reconnect to WiFi!");
    }
  }
}

void setupWebServer() {
  // Enable CORS for all requests
  server.enableCORS(true);
  
  // Handle CORS preflight requests
  server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) {
      handleCORS();
      server.send(200);
    } else {
      handleCORS();
      server.send(404, "text/plain", "Endpoint not found");
    }
  });
  
  // Plant data endpoint
  server.on("/api/plant-data", HTTP_GET, []() {
    handleCORS();
    
    DynamicJsonDocument doc(1024);
    doc["soilMoisture"] = plantData.soilMoisture;
    doc["soilPercent"] = map(plantData.soilMoisture, 4095, 0, 0, 100); // Convert to percentage
    doc["lightLevel"] = plantData.lightLevel;
    doc["lightPercent"] = map(plantData.lightLevel, 0, 4095, 0, 100); // Convert to percentage
    doc["temperature"] = plantData.temperature;
    doc["humidity"] = plantData.humidity;
    doc["status"] = plantData.status;
    doc["emotion"] = plantData.emotion;
    doc["isOnline"] = plantData.isOnline;
    doc["lastUpdate"] = plantData.lastUpdate;
    doc["timestamp"] = millis();
    doc["wifiSignal"] = WiFi.RSSI();
    doc["wifiReconnects"] = plantData.wifiReconnects;
    doc["sensorErrors"] = plantData.sensorErrors;
    doc["uptime"] = millis() / 1000; // Uptime in seconds
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
    
    Serial.println("API request served: /api/plant-data");
  });
  
  // Status endpoint
  server.on("/api/status", HTTP_GET, []() {
    handleCORS();
    
    DynamicJsonDocument doc(512);
    doc["status"] = "online";
    doc["device"] = "Smart Plant Monitor";
    doc["version"] = "2.1";
    doc["uptime"] = millis() / 1000;
    doc["freeHeap"] = ESP.getFreeHeap();
    doc["wifiStatus"] = (WiFi.status() == WL_CONNECTED) ? "connected" : "disconnected";
    doc["ip"] = WiFi.localIP().toString();
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
    
    Serial.println("API request served: /api/status");
  });
  
  // Debug endpoint
  server.on("/api/debug", HTTP_GET, []() {
    handleCORS();
    
    DynamicJsonDocument doc(1024);
    doc["wifiSSID"] = WiFi.SSID();
    doc["wifiRSSI"] = WiFi.RSSI();
    doc["wifiReconnects"] = plantData.wifiReconnects;
    doc["sensorErrors"] = plantData.sensorErrors;
    doc["freeHeap"] = ESP.getFreeHeap();
    doc["chipModel"] = ESP.getChipModel();
    doc["chipRevision"] = ESP.getChipRevision();
    doc["cpuFreq"] = ESP.getCpuFreqMHz();
    doc["flashSize"] = ESP.getFlashChipSize();
    doc["uptime"] = millis() / 1000;
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
    
    Serial.println("API request served: /api/debug");
  });
  
  // Root endpoint
  server.on("/", HTTP_GET, []() {
    handleCORS();
    String html = "<!DOCTYPE html><html><head><title>Smart Plant Monitor</title></head>";
    html += "<body><h1>Smart Plant Monitor v2.1</h1>";
    html += "<p>Device is online and running!</p>";
    html += "<h2>API Endpoints:</h2>";
    html += "<ul>";
    html += "<li><a href='/api/plant-data'>/api/plant-data</a> - Get plant sensor data</li>";
    html += "<li><a href='/api/status'>/api/status</a> - Get device status</li>";
    html += "<li><a href='/api/debug'>/api/debug</a> - Get debug information</li>";
    html += "</ul>";
    html += "<p>Current Status: " + plantData.status + "</p>";
    html += "<p>Emotion: " + plantData.emotion + "</p>";
    html += "</body></html>";
    
    server.send(200, "text/html", html);
    Serial.println("Web page served");
  });
  
  server.begin();
  Serial.println("HTTP server started on port 80");
  Serial.println("Available endpoints:");
  Serial.println("  - http://[IP]/");
  Serial.println("  - http://[IP]/api/plant-data");
  Serial.println("  - http://[IP]/api/status");
  Serial.println("  - http://[IP]/api/debug");
}

void handleCORS() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
  server.sendHeader("Access-Control-Max-Age", "86400");
}

void readSensors() {
  // Read analog sensors with multiple samples for stability
  int soilSum = 0, lightSum = 0;
  const int samples = 5;
  
  for (int i = 0; i < samples; i++) {
    soilSum += analogRead(soilPin);
    lightSum += analogRead(ldrPin);
    delay(10);
  }
  
  plantData.soilMoisture = soilSum / samples;
  plantData.lightLevel = lightSum / samples;
  
  // Read DHT sensor with error handling
  float tempReading = dht.readTemperature();
  float humReading = dht.readHumidity();
  
  if (isnan(tempReading) || isnan(humReading)) {
    plantData.sensorErrors++;
    Serial.println("DHT sensor read error");
    
    // Keep previous values if available, otherwise set to 0
    if (plantData.temperature == 0.0) plantData.temperature = 0.0;
    if (plantData.humidity == 0.0) plantData.humidity = 0.0;
  } else {
    plantData.temperature = tempReading;
    plantData.humidity = humReading;
  }
  
  plantData.lastUpdate = millis();
  plantData.isOnline = (WiFi.status() == WL_CONNECTED);
  
  // Debug output every 10 sensor reads
  static int readCount = 0;
  readCount++;
  if (readCount >= 10) {
    Serial.printf("Sensors - Soil: %d, Light: %d, Temp: %.1f°C, Humidity: %.1f%%\n", 
                  plantData.soilMoisture, plantData.lightLevel, 
                  plantData.temperature, plantData.humidity);
    readCount = 0;
  }
}

void updatePlantStatus() {
  // Prioritize conditions (most critical first)
  if (plantData.soilMoisture > drySoil) {
    plantData.status = "Needs Water!";
    plantData.emotion = "sad";
  } 
  else if (plantData.temperature > 35.0) {
    plantData.status = "Too Hot!";
    plantData.emotion = "hot";
  }
  else if (plantData.lightLevel < darkLight) {
    plantData.status = "Too Dark";
    plantData.emotion = "sleepy";
  } 
  else if (plantData.lightLevel > brightLight) {
    plantData.status = "Too Bright";
    plantData.emotion = "hot";
  }
  else if (plantData.soilMoisture < wetSoil) {
    plantData.status = "Too Wet";
    plantData.emotion = "neutral";
  }
  else if (plantData.humidity < 30) {
    plantData.status = "Dry Air";
    plantData.emotion = "neutral";
  }
  else {
    plantData.status = "Happy!";
    plantData.emotion = "happy";
  }
}

void showStartupScreen() {
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(WHITE);
  display.setCursor(0,0);
  display.println("Smart");
  display.println("Plant");
  display.setTextSize(1);
  display.println("Monitor v2.1");
  display.println("");
  display.println("Initializing...");
  display.display();
  delay(2000);
}

void updateDisplay() {
  display.clearDisplay();
  
  // Draw appropriate face based on plant status
  if (plantData.emotion == "sad") {
    drawSadFace();
  } else if (plantData.emotion == "sleepy") {
    drawSleepyFace();
  } else if (plantData.emotion == "hot") {
    drawHotFace();
  } else if (plantData.emotion == "neutral") {
    drawNeutralFace();
  } else {
    drawHappyFace();
  }
  
  // Display status (top-left)
  display.setCursor(0, 0);
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.println(plantData.status);
  
  // WiFi status indicator (top-right)
  if (WiFi.status() == WL_CONNECTED) {
    display.setCursor(120, 0);
    display.print("W");
  }
  
  // Display sensor readings (bottom section)
  display.setCursor(0, 48);
  display.print("S:");
  display.print(plantData.soilMoisture);
  display.print(" L:");
  display.print(plantData.lightLevel);
  
  display.setCursor(0, 56);
  if (plantData.temperature > 0) {
    display.print("T:");
    display.print(plantData.temperature, 1);
    display.print("C");
  }
  if (plantData.humidity > 0) {
    display.print(" H:");
    display.print(plantData.humidity, 0);
    display.print("%");
  }
  
  display.display();
}

void drawHappyFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  // Eyes
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  // Smile
  display.fillCircle(64, 38, 10, WHITE);
  display.fillCircle(64, 36, 10, BLACK);
}

void drawSadFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  // Eyes
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  // Frown
  display.fillCircle(64, 42, 10, WHITE);
  display.fillCircle(64, 44, 10, BLACK);
}

void drawSleepyFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  // Sleepy eyes (lines)
  display.drawLine(52, 26, 60, 26, WHITE);
  display.drawLine(68, 26, 76, 26, WHITE);
  // Neutral mouth
  display.drawLine(54, 38, 74, 38, WHITE);
}

void drawHotFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  // Eyes
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  // Straight mouth
  display.drawLine(54, 38, 74, 38, WHITE);
  // Heat lines above head
  display.drawLine(64, 15, 64, 10, WHITE);
  display.drawLine(60, 18, 55, 13, WHITE);
  display.drawLine(68, 18, 73, 13, WHITE);
}

void drawNeutralFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  // Eyes
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  // Neutral mouth
  display.drawLine(54, 38, 74, 38, WHITE);
}

void printDebugInfo() {
  Serial.println("=== DEBUG INFO ===");
  Serial.printf("Uptime: %lu seconds\n", millis() / 1000);
  Serial.printf("WiFi Status: %s\n", (WiFi.status() == WL_CONNECTED) ? "Connected" : "Disconnected");
  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("IP Address: %s\n", WiFi.localIP().toString().c_str());
    Serial.printf("Signal Strength: %d dBm\n", WiFi.RSSI());
  }
  Serial.printf("WiFi Reconnects: %d\n", plantData.wifiReconnects);
  Serial.printf("Sensor Errors: %d\n", plantData.sensorErrors);
  Serial.printf("Free Heap: %d bytes\n", ESP.getFreeHeap());
  Serial.printf("Plant Status: %s (%s)\n", plantData.status.c_str(), plantData.emotion.c_str());
  Serial.println("==================");
}