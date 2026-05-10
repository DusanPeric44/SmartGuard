#include "esp_camera.h"
#include <WiFi.h>
#include "camera_pins.h"
#include "WifiProvisioner.h"
#include "StreamManager.h"
#include "StorageManager.h"
#include "SecurityManager.h"

// Configuration
#define PIR_PIN 13
#define SIGNALR_HOST "192.168.100.60"
#define SIGNALR_PORT 5000
#define SIGNALR_PATH "/hub/camera"
#define BACKEND_SYNC_URL "http://192.168.100.60:5000/upload"

void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();

  // 1. WiFi Provisioning
  setupWifiProvisioning();

  // 2. Camera Initialization
  Serial.println("Initializing Camera...");
  
  // Manually power-cycle the camera to ensure it's responsive
  if (PWDN_GPIO_NUM != -1) {
    pinMode(PWDN_GPIO_NUM, OUTPUT);
    digitalWrite(PWDN_GPIO_NUM, HIGH); // Power down
    delay(100);
    digitalWrite(PWDN_GPIO_NUM, LOW);  // Power up
    delay(100);
  }

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 10000000; // Lowered from 20MHz for better stability during probe
  config.pixel_format = PIXFORMAT_JPEG;
  
  if(psramFound()){
    config.frame_size = FRAMESIZE_VGA; // Use VGA for better performance with face detection
    config.jpeg_quality = 12;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_QVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }

  // 3. Initialize Components
  Serial.println("Initializing Stream Manager...");
  setupStreamManager(SIGNALR_HOST, SIGNALR_PORT, SIGNALR_PATH);
  
  Serial.println("Initializing Storage Manager...");
  setupStorageManager();
  
  Serial.println("Initializing Security Manager...");
  setupSecurityManager(PIR_PIN);

  // 4. Device Registration (if not already registered)
  Serial.println("Checking device registration...");
  String deviceToken = getDeviceToken();
  if (deviceToken == "") {
    Serial.println("Device not registered. Attempting registration...");
    String registrationKey = getRegistrationKey();
    if (registrationKey != "") {
      Serial.println("Attempting to connect with registartion key: " + registrationKey);
      if (registerDevice("http://192.168.100.60:5000", registrationKey.c_str())) {
        Serial.println("Device registered successfully!");
      } else {
        Serial.println("Device registration failed.");
      }
    } else {
      Serial.println("No registration key found. Skipping registration.");
    }
  } else {
    Serial.println("Device already registered with token: " + deviceToken);
  }

  Serial.println("System initialized and ready.");
}

unsigned long lastSyncTime = 0;
const unsigned long SYNC_INTERVAL = 300000; // Sync every 5 minutes

void loop() {
  // Capture a frame for security and recording
  camera_fb_t* fb = esp_camera_fb_get();
  
  if (fb) {
    // 4. Security Check (PIR + Face)
    bool motionDetected = checkSecurity(fb);

    // 5. Recording Logic
    handleRecording(motionDetected);
    recordFrame(fb);

    esp_camera_fb_return(fb);
  }

  // 6. SignalR Communication & Streaming
  handleStream();

  // 7. Background Sync
  if (millis() - lastSyncTime > SYNC_INTERVAL) {
    syncFilesToBackend(BACKEND_SYNC_URL);
    lastSyncTime = millis();
  }

  delay(10);
}
