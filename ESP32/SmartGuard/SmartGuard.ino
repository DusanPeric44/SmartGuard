#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include "camera_pins.h"
#include "WifiProvisioner.h"
#include "StreamManager.h"
#include "StorageManager.h"
#include "SecurityManager.h"
#include "FlashManager.h"

// Configuration
#define PIR_PIN 13
#define SIGNALR_HOST "10.15.225.19"
#define SIGNALR_PORT 5000
#define BACKEND_SYNC_URL "http://10.15.225.19:5001/upload"
#define BACKEND_BASE_URL "http://10.15.225.19:5000"

String webSocketPath;
Preferences devicePrefs;

bool validateDevice(const char* serverBaseUrl) {
  if (WiFi.status() != WL_CONNECTED) return false;

  String token = getDeviceToken();
  int id = getDeviceId();
  if (token == "" || id <= 0) return false;

  HTTPClient http;
  String url = String(serverBaseUrl) + "/Devices/validate";
  http.begin(url);
  http.addHeader("X-Device-Id", String(id));
  http.addHeader("X-Device-Token", token);

  int responseCode = http.GET();
  http.end();

  return responseCode == 200;
}

void clearDeviceCredentials() {
  devicePrefs.begin("smartguard", false);
  devicePrefs.remove("device_token");
  devicePrefs.remove("device_id");
  devicePrefs.end();
}

void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();

  setupFlashManager();

  // 1. WiFi Connection or Provisioning
  if (!connectToStoredWifi()) {
    Serial.println("Starting WiFi Provisioning...");
    setupWifiProvisioning();
  }

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
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  
  if(psramFound()){
    config.frame_size = FRAMESIZE_QVGA; // Use VGA for better performance with face detection
    config.jpeg_quality = 10;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_QVGA;
    config.jpeg_quality = 10;
    config.fb_count = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }

  sensor_t *s = esp_camera_sensor_get();
  if (s) {
    s->set_brightness(s, 1);
    s->set_contrast(s, 1);
    s->set_saturation(s, 0);
    s->set_sharpness(s, 1);
    s->set_denoise(s, 1);
    s->set_special_effect(s, 0);
    s->set_whitebal(s, 1);
    s->set_awb_gain(s, 1);
    s->set_wb_mode(s, 0);
    s->set_exposure_ctrl(s, 1);
    s->set_aec2(s, 1);
    s->set_ae_level(s, 0);
    s->set_gain_ctrl(s, 1);
    s->set_agc_gain(s, 5);
    s->set_hmirror(s, 0);
    s->set_vflip(s, 0);
  }

  // 3. Initialize Components
  Serial.println("Initializing Storage Manager...");
  setupStorageManager();
  
  Serial.println("Initializing Security Manager...");
  setupSecurityManager(PIR_PIN);

  // 4. Device Registration (if not already registered)
  Serial.println("Checking device registration...");
  String deviceToken = getDeviceToken();
  int deviceId = getDeviceId();

  if (deviceToken != "" && deviceId > 0) {
    Serial.println("Validating device registration with backend...");
    if (!validateDevice(BACKEND_BASE_URL)) {
      Serial.println("Device validation failed. Clearing credentials and waiting for Flutter provisioning...");
      clearDeviceCredentials();
      deviceToken = "";
      deviceId = 0;
      setupWifiProvisioning();
    } else {
      Serial.println("Device validation OK.");
    }
  }

  if (deviceToken == "" || deviceId <= 0) {
    Serial.println("Device not registered (or missing ID). Attempting registration...");
    String registrationKey = getRegistrationKey();
    if (registrationKey != "") {
      Serial.println("Attempting to connect with registration key: " + registrationKey);
      if (registerDevice(BACKEND_BASE_URL, registrationKey.c_str())) {
        Serial.println("Device registered successfully!");
        deviceId = getDeviceId();
      } else {
        Serial.println("Device registration failed.");
        clearDeviceCredentials();
        deviceToken = "";
        deviceId = 0;
        setupWifiProvisioning();
      }
    } else {
      Serial.println("No registration key found. Skipping registration.");
    }
  } else {
    Serial.println("Device already registered with token: " + deviceToken);
  }

  if (deviceId > 0) {
    webSocketPath = String("/api/esp32/ws?deviceId=") + String(deviceId);
    Serial.println("Initializing Stream Manager with path: " + webSocketPath);
    setupStreamManager(SIGNALR_HOST, SIGNALR_PORT, webSocketPath.c_str());
  } else {
    Serial.println("Device ID not available. Stream Manager not started.");
  }

  Serial.println("System initialized and ready.");
}

void loop() {
  // Ensure WebSocket is serviced even if subsequent operations take time
  handleStream(NULL);

  // Capture a single frame for all components
  camera_fb_t* fb = esp_camera_fb_get();
  
  if (fb) {
    // 4. Security Check (PIR + Face)
    bool motionDetected = checkSecurity(fb);
    bool notifyFaceEvent = consumeNotifyFaceEvent();

    // 5. Recording Logic
    handleRecording(motionDetected, notifyFaceEvent, BACKEND_SYNC_URL);
    recordFrame(fb);

    // 6. Streaming (Pass the existing frame)
    handleStream(fb);

    esp_camera_fb_return(fb);
  } else {
    // If no frame, still call handleStream to process WebSocket events/pings
    handleStream(NULL);
  }

  delay(10);
}
