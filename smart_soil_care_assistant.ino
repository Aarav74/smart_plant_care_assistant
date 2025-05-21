#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDR 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// Sensor Pins
const int soilPin = 36;  // GPIO36 (Analog VP)
const int ldrPin = 39;   // GPIO39 (Analog VN)

// Thresholds (Adjust based on your sensors)
const int drySoil = 1500;  // Below = Needs water
const int darkLight = 500; // Below = Too dark
const int brightLight = 3000; // Above = Too bright

void setup() {
  Serial.begin(115200);
  
  // Initialize I2C with default pins (SDA=21, SCL=22)
  Wire.begin();
  
  // Initialize OLED
  if(!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("OLED not found!");
    while(1);
  }
  
  // Show startup animation
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0,0);
  display.println("Plant Monitor");
  display.println("Initializing...");
  display.display();
  delay(2000);
}

void loop() {
  int soilValue = analogRead(soilPin);
  int lightValue = analogRead(ldrPin);

  display.clearDisplay();
  
  // Determine plant emotion
  if (soilValue < drySoil) {
    drawSadFace();
    display.setCursor(0, 0);
    display.print("Water me!");
  } 
  else if (lightValue < darkLight) {
    drawSleepyFace();
    display.setCursor(0, 0);
    display.print("Too dark...");
  } 
  else if (lightValue > brightLight) {
    drawHotFace();
    display.setCursor(0, 0);
    display.print("Too bright!");
  } 
  else {
    drawHappyFace();
    display.setCursor(0, 0);
    display.print("I'm happy!");
  }

  // Display sensor data
  display.setCursor(0, 54);
  display.print("Soil:");
  display.print(soilValue);
  display.print(" Light:");
  display.print(lightValue);

  display.display();
  delay(2000); // Update every 2 sec
}

// Emoji Drawing Functions (using available methods)
void drawHappyFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  
  // Eyes
  display.fillCircle(56, 26, 3, WHITE);  // Left eye
  display.fillCircle(72, 26, 3, WHITE);  // Right eye
  
  // Smile (using filled circle with erase)
  display.fillCircle(64, 38, 10, WHITE);
  display.fillCircle(64, 36, 10, BLACK);
}

void drawSadFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  
  // Eyes
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  
  // Frown (using filled circle with erase)
  display.fillCircle(64, 42, 10, WHITE);
  display.fillCircle(64, 44, 10, BLACK);
}

void drawSleepyFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  
  // Closed eyes
  display.drawLine(52, 26, 60, 26, WHITE); // Left eye
  display.drawLine(68, 26, 76, 26, WHITE); // Right eye
  
  // Small smile
  display.drawLine(54, 38, 74, 38, WHITE);
}

void drawHotFace() {
  // Face outline
  display.drawCircle(64, 32, 20, WHITE);
  
  // Eyes
  display.fillCircle(56, 26, 3, WHITE);
  display.fillCircle(72, 26, 3, WHITE);
  
  // Smile
  display.drawLine(54, 38, 74, 38, WHITE);
  
  // Heat lines
  display.drawLine(64, 15, 64, 10, WHITE);
  display.drawLine(60, 18, 55, 13, WHITE);
  display.drawLine(68, 18, 73, 13, WHITE);
}
