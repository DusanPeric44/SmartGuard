#include <vector>
#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include "SecurityManager.h"
#include "fd_forward.h"
#include "fr_forward.h"

#undef max
#undef min

int _pirPin;
bool _motionDetected = false;
std::vector<int> safeFaceIds;
Preferences preferences;

static mtmn_config_t mtmn_config = {0};
static face_id_list id_list = {0};

int allocateFallbackFaceId() {
  preferences.begin("smartguard", false);
  int next = preferences.getInt("fallback_face_id", 1000);
  preferences.putInt("fallback_face_id", next + 1);
  preferences.end();
  return next;
}

void setupSecurityManager(int pirPin) {
  _pirPin = pirPin;
  pinMode(_pirPin, INPUT);

  // Initialize face detection config (copied from boilerplate)
  mtmn_config.type = FAST;
  mtmn_config.min_face = 80;
  mtmn_config.pyramid = 0.707;
  mtmn_config.pyramid_times = 4;
  mtmn_config.p_threshold.score = 0.6;
  mtmn_config.p_threshold.nms = 0.7;
  mtmn_config.p_threshold.candidate_number = 20;
  mtmn_config.r_threshold.score = 0.7;
  mtmn_config.r_threshold.nms = 0.7;
  mtmn_config.r_threshold.candidate_number = 10;
  mtmn_config.o_threshold.score = 0.7;
  mtmn_config.o_threshold.nms = 0.7;
  mtmn_config.o_threshold.candidate_number = 1;

  face_id_init(&id_list, 7, 5); // 7 faces, 5 samples each
}

bool registerDevice(const char* serverUrl, const char* registrationKey) {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String url = String(serverUrl) + "/Devices/register";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  JsonDocument doc;
  doc["macAddress"] = WiFi.macAddress();
  doc["registrationKey"] = registrationKey;

  String requestBody;
  serializeJson(doc, requestBody);

  int httpResponseCode = http.POST(requestBody);
  bool success = false;

  if (httpResponseCode == 200) {
    String response = http.getString();
    JsonDocument resDoc;
    deserializeJson(resDoc, response);
    
    String deviceToken = resDoc["apiKey"] | "";
    int deviceId = resDoc["id"] | 0;
    if (deviceId <= 0) deviceId = resDoc["Id"] | 0;

    if (deviceToken != "" && deviceId > 0) {
      preferences.begin("smartguard", false);
      preferences.putString("device_token", deviceToken);
      preferences.putInt("device_id", deviceId);
      preferences.end();
      Serial.printf("Device registered successfully. Token and ID saved (id=%d).\n", deviceId);
      success = true;
    } else {
      Serial.print("Registration response missing required fields. tokenLength=");
      Serial.print(deviceToken.length());
      Serial.print(" deviceId=");
      Serial.println(deviceId);
    }
  } else {
    Serial.print("Error on registration: ");
    Serial.println(httpResponseCode);
  }

  http.end();
  return success;
}

String getDeviceToken() {
  preferences.begin("smartguard", true);
  String token = preferences.getString("device_token", "");
  preferences.end();
  return token;
}

int getDeviceId() {
  preferences.begin("smartguard", true);
  int id = preferences.getInt("device_id", 0);
  preferences.end();
  return id;
}

void sendIntruderAlert(camera_fb_t* fb, int faceId) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = "http://10.15.225.19:5000/faceDetectionEvents/detect";
  http.begin(url);
  http.addHeader("Content-Type", "image/jpeg");
  http.addHeader("X-Face-Id", String(faceId));
  http.addHeader("X-Device-Id", String(getDeviceId()));
  http.addHeader("X-Device-Token", getDeviceToken());
  
  int response = http.POST(fb->buf, fb->len);
  Serial.println("Face detection event sent. Response: " + String(response));
  http.end();
}

void sendSafeMotionAlert() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  http.begin("http://10.15.225.19:5000/security/safe-motion");
  http.POST("{\"message\": \"Safe person detected\"}");
  http.end();
}

bool checkSecurity(camera_fb_t* fb) {
  _motionDetected = digitalRead(_pirPin);

  if (_motionDetected && fb) {
    // Perform Face Detection
    dl_matrix3du_t *image_matrix = dl_matrix3du_alloc(1, fb->width, fb->height, 3);
    if (!image_matrix) return true;

    if (fmt2rgb888(fb->buf, fb->len, fb->format, image_matrix->item)) {
      box_array_t *net_boxes = face_detect(image_matrix, &mtmn_config);
      if (net_boxes) {
        // Face detected, now recognize
        dl_matrix3du_t *aligned_face = dl_matrix3du_alloc(1, FACE_WIDTH, FACE_HEIGHT, 3);
        if (align_face(net_boxes, image_matrix, aligned_face) == ESP_OK) {
          int matched_id = recognize_face(&id_list, aligned_face);
          
          int faceIdToSend = matched_id;
          if (faceIdToSend < 0) {
            int enrolledId = enroll_face(&id_list, aligned_face);
            faceIdToSend = enrolledId >= 0 ? enrolledId : allocateFallbackFaceId();
          }

          if (isFaceSafe(faceIdToSend)) {
            Serial.println("Safe person detected: " + String(faceIdToSend));
          } else {
            Serial.println("Intruder detected!");
          }

          sendIntruderAlert(fb, faceIdToSend);
        }
        dl_matrix3du_free(aligned_face);
        dl_lib_free(net_boxes->score);
        dl_lib_free(net_boxes->box);
        if (net_boxes->landmark != NULL) dl_lib_free(net_boxes->landmark);
        dl_lib_free(net_boxes);
      }
    }
    dl_matrix3du_free(image_matrix);
  }

  return _motionDetected;
}

void markFaceAsSafe(int faceId) {
  if (!isFaceSafe(faceId)) {
    safeFaceIds.push_back(faceId);
    Serial.println("Face ID " + String(faceId) + " marked as safe.");
  }
}

bool isFaceSafe(int faceId) {
  if (faceId < 0) return false;
  for (int id : safeFaceIds) {
    if (id == faceId) return true;
  }
  return false;
}
