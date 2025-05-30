#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// OLED Setup
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDRESS 0x3C
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// UART komunikasi dengan ESP32-CAM (slave)
#define RXD2 16  // RX master ← TX slave
#define TXD2 17  // TX master → RX slave

// Ultrasonik
#define trigPinFront 32
#define echoPinFront 33
#define trigPinRight 18
#define echoPinRight 19
#define trigPinLeft  5
#define echoPinLeft  23

// Motor driver
#define in1 12  // Motor kanan
#define in2 14
#define in3 27  // Motor kiri
#define in4 26
#define ena 13
#define enb 25

// Sensor api lokal & buzzer
#define flamePin 15
#define buzzerPin 4

// Kalman filter
float kalmanGain = 0.6;
float estFront = 0, estLeft = 0, estRight = 0;

float kalmanFilter(float raw, float prevEst) {
  return kalmanGain * raw + (1 - kalmanGain) * prevEst;
}

// Fuzzy membership
float trapezoid(float x, float a, float b, float c, float d) {
  if (x <= a || x >= d) return 0;
  else if (x >= b && x <= c) return 1;
  else if (x > a && x < b) return (x - a) / (b - a);
  else return (d - x) / (d - c);
}

float triangle(float x, float a, float b, float c) {
  if (x <= a || x >= c) return 0;
  else if (x == b) return 1;
  else if (x > a && x < b) return (x - a) / (b - a);
  else return (c - x) / (c - b);
}

int fuzzySpeed(float dist) {
  float dekat = trapezoid(dist, 0, 0, 10, 20);
  float sedang = triangle(dist, 10, 25, 40);
  float jauh = trapezoid(dist, 30, 40, 80, 100);
  float z1 = 100, z2 = 180, z3 = 255;
  float num = dekat*z1 + sedang*z2 + jauh*z3;
  float den = dekat + sedang + jauh;
  return (den == 0) ? 100 : (int)(num / den);
}

// Variabel komunikasi dengan slave
String slaveData = "";
bool apiSlave = false;
int gasValue = 0;

void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2); // UART ke ESP32-CAM

  pinMode(in1, OUTPUT); pinMode(in2, OUTPUT);
  pinMode(in3, OUTPUT); pinMode(in4, OUTPUT);
  pinMode(ena, OUTPUT); pinMode(enb, OUTPUT);
  digitalWrite(ena, HIGH); digitalWrite(enb, HIGH);

  pinMode(trigPinFront, OUTPUT); pinMode(echoPinFront, INPUT);
  pinMode(trigPinRight, OUTPUT); pinMode(echoPinRight, INPUT);
  pinMode(trigPinLeft, OUTPUT); pinMode(echoPinLeft, INPUT);

  pinMode(flamePin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, LOW);

  Wire.begin(21, 22);
  if(!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS)) {
    Serial.println("OLED gagal");
    while(1);
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0,0);
  display.println("Robot siap");
  display.display();
  delay(1000);
}

long readUltrasonic(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW); delayMicroseconds(2);
  digitalWrite(trigPin, HIGH); delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  long durasi = pulseIn(echoPin, HIGH, 30000);
  long jarak = durasi * 0.034 / 2;
  return (jarak == 0 || jarak > 300) ? 300 : jarak;
}

void maju() {
  digitalWrite(in1, HIGH); digitalWrite(in2, LOW);
  digitalWrite(in3, HIGH); digitalWrite(in4, LOW);
}
void mundur() {
  digitalWrite(in1, LOW); digitalWrite(in2, HIGH);
  digitalWrite(in3, LOW); digitalWrite(in4, HIGH);
}
void belokKiri() {
  digitalWrite(in1, HIGH); digitalWrite(in2, LOW);
  digitalWrite(in3, LOW); digitalWrite(in4, HIGH);
}
void belokKanan() {
  digitalWrite(in1, LOW); digitalWrite(in2, HIGH);
  digitalWrite(in3, HIGH); digitalWrite(in4, LOW);
}
void berhenti() {
  digitalWrite(in1, LOW); digitalWrite(in2, LOW);
  digitalWrite(in3, LOW); digitalWrite(in4, LOW);
}

void loop() {
  long dFront = readUltrasonic(trigPinFront, echoPinFront);
  long dLeft = readUltrasonic(trigPinLeft, echoPinLeft);
  long dRight = readUltrasonic(trigPinRight, echoPinRight);

  estFront = kalmanFilter(dFront, estFront);
  estLeft = kalmanFilter(dLeft, estLeft);
  estRight = kalmanFilter(dRight, estRight);

  int speed = fuzzySpeed(estFront);

  bool apiLokal = (digitalRead(flamePin) == LOW);
  digitalWrite(buzzerPin, (apiLokal || apiSlave) ? HIGH : LOW);

  // Tampilkan data
  Serial.print("Depan: "); Serial.print(estFront);
  Serial.print(" | Kiri: "); Serial.print(estLeft);
  Serial.print(" | Kanan: "); Serial.print(estRight);
  Serial.print(" | Api: "); Serial.print(apiLokal || apiSlave ? "TERDETEKSI" : "AMAN");
  Serial.print(" | Gas: "); Serial.println(gasValue);

  display.clearDisplay();
  display.setCursor(0,0); display.print("Depan: "); display.print(estFront);
  display.setCursor(0,10); display.print("Kiri : "); display.print(estLeft);
  display.setCursor(0,20); display.print("Kanan: "); display.print(estRight);
  display.setCursor(0,30); display.print("Speed: "); display.print(speed);
  display.setCursor(0,40);
  display.print((apiLokal || apiSlave) ? "🔥 Api Terdeteksi!" : "Aman");
  display.setCursor(0,50);
  display.print("Gas: "); display.print(gasValue);
  display.display();

  // === LOGIKA KENDALI ===
  if (apiLokal || apiSlave) {
    berhenti();
  } else if (estFront < 20) {
    berhenti(); delay(200);
    if (estLeft > estRight) belokKiri();
    else belokKanan();
    delay(500);
  } else if (estRight < 15) {
    belokKiri(); delay(300);
  } else if (estLeft < 15) {
    belokKanan(); delay(300);
  } else {
    maju();
  }

  // === BACA DATA DARI SLAVE ===
  while (Serial2.available()) {
    char c = Serial2.read();
    if (c == '\n') {
      if (slaveData.startsWith("SENSOR:")) {
        int idxFlame = slaveData.indexOf("FLAME=");
        int idxGas = slaveData.indexOf("GAS=");
        if (idxFlame != -1 && idxGas != -1) {
          apiSlave = slaveData.substring(idxFlame + 6, slaveData.indexOf(';')).toInt();
          gasValue = slaveData.substring(idxGas + 4).toInt();
        }
      }
      slaveData = "";
    } else {
      slaveData += c;
    }
  }

  // === KIRIM PERINTAH KE SLAVE ===
  if (apiLokal || apiSlave) {
    Serial2.println("CMD:EXTINGUISH");
  } else {
    Serial2.println("CMD:STOP");
  }

  delay(100);
}
