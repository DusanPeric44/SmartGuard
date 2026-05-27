#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <cstring>
#include <math.h>
#include "SecurityManager.h"
#include "fd_forward.h"
#include "fr_forward.h"

#undef max
#undef min

int _pirPin;
bool _motionDetected = false;
Preferences preferences;

static mtmn_config_t mtmn_config = {0};
static bool g_notifyFaceEvent = false;
static String g_backendBaseUrl = "";

static bool parseHttpBaseUrl(const String& baseUrl, String& host, uint16_t& port) {
  if (baseUrl.length() == 0) return false;

  String u = baseUrl;
  if (u.startsWith("http://")) {
    u = u.substring(7);
  }

  int slash = u.indexOf('/');
  if (slash >= 0) {
    u = u.substring(0, slash);
  }

  int colon = u.indexOf(':');
  if (colon >= 0) {
    host = u.substring(0, colon);
    port = (uint16_t)u.substring(colon + 1).toInt();
  } else {
    host = u;
    port = 80;
  }

  return host.length() > 0 && port > 0;
}

static void writeChunk(WiFiClient& client, const char* data, size_t len) {
  char header[16];
  snprintf(header, sizeof(header), "%X\r\n", (unsigned)len);
  client.write((const uint8_t*)header, strlen(header));
  client.write((const uint8_t*)data, len);
  client.write((const uint8_t*)"\r\n", 2);
}

bool consumeNotifyFaceEvent() {
  if (!g_notifyFaceEvent) return false;
  g_notifyFaceEvent = false;
  return true;
}

static bool tryGetFaceEmbedding(dl_matrix3du_t *image_matrix, box_array_t *net_boxes, float outEmbedding[128]) {
  dl_matrix3du_t *aligned_face = dl_matrix3du_alloc(1, FACE_WIDTH, FACE_HEIGHT, 3);
  if (!aligned_face) {
    return false;
  }

  if (align_face(net_boxes, image_matrix, aligned_face) != ESP_OK) {
    dl_matrix3du_free(aligned_face);
    return false;
  }

  auto embedding = get_face_id(aligned_face);
  dl_matrix3du_free(aligned_face);

  if (!embedding) {
    return false;
  }

  memcpy(outEmbedding, embedding->item, sizeof(float) * 128);
  dl_matrix3d_free(embedding);

  for (int i = 0; i < 128; i++) {
    if (!isfinite(outEmbedding[i])) {
      return false;
    }
  }

  return true;
}

static void sendFaceDetectionEvent(camera_fb_t* fb, const float* embedding, size_t embeddingLen) {
  if (WiFi.status() != WL_CONNECTED) return;
  if (!fb || !fb->buf || fb->len == 0) return;
  if (!embedding || embeddingLen != 128) return;

  String host;
  uint16_t port = 0;
  if (!parseHttpBaseUrl(g_backendBaseUrl, host, port)) return;

  WiFiClient client;
  if (!client.connect(host.c_str(), port)) return;

  const String path = "/FaceDetectionEvents/detect";
  client.print("POST " + path + " HTTP/1.1\r\n");
  client.print("Host: " + host + "\r\n");
  client.print("Content-Type: application/json\r\n");
  client.print("X-Device-Token: " + getDeviceToken() + "\r\n");
  client.print("Transfer-Encoding: chunked\r\n");
  client.print("Connection: close\r\n\r\n");

  const int deviceId = getDeviceId();

  String prefix = "{\"deviceId\":";
  prefix += deviceId;
  prefix += ",\"imageBytes\":[";
  writeChunk(client, prefix.c_str(), prefix.length());

  char buf[512];
  size_t idx = 0;
  for (size_t i = 0; i < fb->len; i++) {
    if (idx > sizeof(buf) - 8) {
      writeChunk(client, buf, idx);
      idx = 0;
    }
    if (i > 0) {
      buf[idx++] = ',';
    }
    idx += snprintf(buf + idx, sizeof(buf) - idx, "%u", (unsigned)fb->buf[i]);
  }
  if (idx > 0) {
    writeChunk(client, buf, idx);
  }

  const char* middle = "],\"vector\":[";
  writeChunk(client, middle, strlen(middle));

  idx = 0;
  for (size_t i = 0; i < embeddingLen; i++) {
    if (idx > sizeof(buf) - 16) {
      writeChunk(client, buf, idx);
      idx = 0;
    }
    if (i > 0) {
      buf[idx++] = ',';
    }
    idx += snprintf(buf + idx, sizeof(buf) - idx, "%.6f", (double)embedding[i]);
  }
  if (idx > 0) {
    writeChunk(client, buf, idx);
  }

  const char* suffix = "]}";
  writeChunk(client, suffix, strlen(suffix));

  client.print("0\r\n\r\n");

  String statusLine = client.readStringUntil('\n');
  String responseBody = client.readString();
  Serial.println("Face detection event sent. " + statusLine);
  if (responseBody.length() > 0) {
    Serial.println("Response body: " + responseBody);
  }
  client.stop();
}

void setupSecurityManager(int pirPin, const char* backendBaseUrl) {
  _pirPin = pirPin;
  pinMode(_pirPin, INPUT);
  g_backendBaseUrl = backendBaseUrl ? String(backendBaseUrl) : "";

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

bool checkSecurity(camera_fb_t* fb) {
  _motionDetected = digitalRead(_pirPin);

  if (_motionDetected && fb) {
    // Perform Face Detection
    dl_matrix3du_t *image_matrix = dl_matrix3du_alloc(1, fb->width, fb->height, 3);
    if (!image_matrix) {
      return true;
    }

    if (fmt2rgb888(fb->buf, fb->len, fb->format, image_matrix->item)) {
      box_array_t *net_boxes = face_detect(image_matrix, &mtmn_config);
      if (net_boxes) {
        float embedding[128];
        if (tryGetFaceEmbedding(image_matrix, net_boxes, embedding)) {
          g_notifyFaceEvent = true;
          sendFaceDetectionEvent(fb, embedding, 128);
        }

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
