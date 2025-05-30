#include "esp_camera.h"
#include <WiFi.h>

// Konfigurasi WiFi
const char* ssid = "Raduwe yo wis";
const char* password = "yyyyyyyy";

// Pin sensor & aktuator
#define FLAME_SENSOR 4
#define GAS_SENSOR 34
#define FAN_PIN 2

String inputCmd = "";

void startCameraServer(); // Dideklarasi di bawah

void setup() {
  Serial.begin(115200);
  pinMode(FLAME_SENSOR, INPUT);
  pinMode(GAS_SENSOR, INPUT);
  pinMode(FAN_PIN, OUTPUT);
  digitalWrite(FAN_PIN, LOW);

  // Inisialisasi kamera
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0 = 5;  config.pin_d1 = 18;
  config.pin_d2 = 19; config.pin_d3 = 21;
  config.pin_d4 = 36; config.pin_d5 = 39;
  config.pin_d6 = 34; config.pin_d7 = 35;
  config.pin_xclk = 0; config.pin_pclk = 22;
  config.pin_vsync = 25; config.pin_href = 23;
  config.pin_sscb_sda = 26; config.pin_sscb_scl = 27;
  config.pin_pwdn = 32; config.pin_reset = -1;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_QVGA;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Kamera gagal: 0x%x", err);
    return;
  }

  // Koneksi WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500); Serial.print(".");
  }

  Serial.println("WiFi Terhubung");
  Serial.println("Streaming di: http://" + WiFi.localIP().toString());
  startCameraServer();
}

void loop() {
  // Baca sensor
  int flame = digitalRead(FLAME_SENSOR);
  int gas = analogRead(GAS_SENSOR);

  // Kirim data ke master
  Serial.printf("SENSOR:FLAME=%d;GAS=%d\n", flame == LOW ? 1 : 0, gas);

  // Terima perintah dari master
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n') {
      processCommand(inputCmd);
      inputCmd = "";
    } else {
      inputCmd += c;
    }
  }

  delay(300);
}

void processCommand(String cmd) {
  cmd.trim();
  if (cmd == "CMD:EXTINGUISH") {
    digitalWrite(FAN_PIN, HIGH);
  } else if (cmd == "CMD:STOP") {
    digitalWrite(FAN_PIN, LOW);
  }
}

// Server kamera bawaan
#include <esp_http_server.h>
void startCameraServer() {
  httpd_handle_t stream_httpd = NULL;
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  httpd_start(&stream_httpd, &config);
  // Gunakan bawaan server kamera jika kamu menggunakan contoh `CameraWebServer`
}
