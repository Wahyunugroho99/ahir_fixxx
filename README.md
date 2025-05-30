
🔌 A. ESP32 (MASTER - Robot Kendali)
1. Motor Driver L298N
Komponen	ESP32 Pin
IN1 (kanan)	GPIO 12
IN2 (kanan)	GPIO 14
IN3 (kiri)	GPIO 27
IN4 (kiri)	GPIO 26
ENA (kanan)	GPIO 13
ENB (kiri)	GPIO 25
VCC (motor)	7–12V battery
GND	GND ESP32

2. Sensor Ultrasonik (3 unit)
Posisi	Trig	Echo
Depan	GPIO 32	GPIO 33
Kanan	GPIO 18	GPIO 19
Kiri	GPIO 5	GPIO 23

Note: Semua GND & VCC HC-SR04 ke GND + 5V ESP32

3. Sensor Api (flame sensor – opsional di master)
Keterangan	ESP32 Pin
DO (digital)	GPIO 15
VCC	3.3V
GND	GND

4. Buzzer
Keterangan	ESP32 Pin
+ (input)	GPIO 4
- (ground)	GND

5. OLED SSD1306 (I2C)
Keterangan	ESP32 Pin
SDA	GPIO 21
SCL	GPIO 22
VCC	3.3V / 5V
GND	GND

6. Koneksi Serial ke ESP32-CAM (Slave)
Keterangan	ESP32 Master	ESP32-CAM Slave
TX → RX (kirim)	GPIO 17	GPIO 3
RX ← TX (terima)	GPIO 16	GPIO 1
GND	GND	GND

📷 B. ESP32-CAM (SLAVE – Kamera & Sensor Api/Gas)
1. Sensor Api (flame sensor)
Keterangan	ESP32-CAM Pin
DO	GPIO 4
VCC	3.3V
GND	GND

2. Sensor Gas (MQ-2 / MQ-135)
Keterangan	ESP32-CAM Pin
AO	GPIO 34
VCC	5V
GND	GND

3. Kipas / Servo Pemadam Api
Keterangan	ESP32-CAM Pin
PWM (kontrol)	GPIO 2
VCC	5V
GND	GND

🔋 Power Supply
ESP32 Master dan ESP32-CAM dapat diberi daya dari regulator step-down 5V (contoh: dari baterai 7.4V Li-ion)

Untuk motor L298N, gunakan jalur baterai 7.4V–12V langsung

Pastikan GND semua modul disatukan agar sinyal UART/I2C sinkron

🧠 Tips Tambahan
Selalu upload kode ke ESP32-CAM terlebih dahulu, karena saat RX/TX terhubung ke master, upload tidak bisa dilakukan.

Gunakan kapasitor 1000uF di VCC ESP32-CAM jika kamera tidak stabil

Gunakan level shifter UART bila tegangan tidak seimbang (opsional, karena ESP32 ↔ ESP32 biasanya aman)

