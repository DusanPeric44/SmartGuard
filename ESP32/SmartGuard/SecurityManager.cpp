#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <cstring>
#include <math.h>
#include "SecurityManager.h"
#include "fd_forward.h"
#include "fr_forward.h"
#include "esp_heap_caps.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

#undef max
#undef min

int _pirPin;
bool _motionDetected = false;
Preferences preferences;

static mtmn_config_t mtmn_config = {0};
static volatile bool g_notifyFaceEvent = false;
static String g_backendBaseUrl = "";

static const uint32_t DETECTION_INTERVAL_MS = 300;
static const int STABILITY_THRESHOLD = 3;
static const int DETECT_W = 160;
static const int DETECT_H = 120;
static const float BOX_STABILITY_MAX_CENTER_DELTA = 0.25f;
static const uint32_t EVENT_COOLDOWN_MS = 3000;

typedef struct {
  uint8_t* jpg;
  size_t len;
  uint16_t width;
  uint16_t height;
  pixformat_t format;
  uint32_t capturedMs;
} DetectFrame;

static QueueHandle_t g_detectQueue = NULL;
static TaskHandle_t g_faceTaskHandle = NULL;
static volatile bool g_motionActive = false;
static volatile uint32_t g_lastEnqueueMs = 0;

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

static void downscaleRgb888Nearest(const uint8_t* src, int srcW, int srcH, uint8_t* dst, int dstW, int dstH) {
  for (int y = 0; y < dstH; y++) {
    int srcY = (y * srcH) / dstH;
    const uint8_t* srcRow = src + (srcY * srcW * 3);
    uint8_t* dstRow = dst + (y * dstW * 3);
    for (int x = 0; x < dstW; x++) {
      int srcX = (x * srcW) / dstW;
      const uint8_t* p = srcRow + (srcX * 3);
      uint8_t* q = dstRow + (x * 3);
      q[0] = p[0];
      q[1] = p[1];
      q[2] = p[2];
    }
  }
}

static bool getBestBox(const box_array_t* boxes, int imgW, int imgH, float& outCx, float& outCy) {
  if (!boxes || !boxes->box || boxes->len == 0) return false;

  int bestIdx = -1;
  int bestArea = -1;
  for (int i = 0; i < boxes->len; i++) {
    int x1 = boxes->box[i * 4 + 0];
    int y1 = boxes->box[i * 4 + 1];
    int x2 = boxes->box[i * 4 + 2];
    int y2 = boxes->box[i * 4 + 3];
    int w = x2 - x1;
    int h = y2 - y1;
    int area = w * h;
    if (area > bestArea) {
      bestArea = area;
      bestIdx = i;
    }
  }
  if (bestIdx < 0) return false;

  int x1 = boxes->box[bestIdx * 4 + 0];
  int y1 = boxes->box[bestIdx * 4 + 1];
  int x2 = boxes->box[bestIdx * 4 + 2];
  int y2 = boxes->box[bestIdx * 4 + 3];
  float cx = ((float)x1 + (float)x2) * 0.5f;
  float cy = ((float)y1 + (float)y2) * 0.5f;
  outCx = cx / (float)imgW;
  outCy = cy / (float)imgH;
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

static void faceDetectionTask(void* parameter) {
  dl_matrix3du_t* full_matrix = NULL;
  dl_matrix3du_t* detect_matrix = dl_matrix3du_alloc(1, DETECT_W, DETECT_H, 3);

  int consecutiveDetections = 0;
  bool triggered = false;
  uint32_t lastEventMs = 0;
  bool haveLast = false;
  float lastCx = 0.0f;
  float lastCy = 0.0f;

  for (;;) {
    DetectFrame frame = {};
    if (!g_detectQueue || xQueueReceive(g_detectQueue, &frame, pdMS_TO_TICKS(1000)) != pdTRUE) {
      if (!g_motionActive) {
        consecutiveDetections = 0;
        triggered = false;
        haveLast = false;
      }
      continue;
    }

    if (!g_motionActive) {
      if (frame.jpg) heap_caps_free(frame.jpg);
      consecutiveDetections = 0;
      triggered = false;
      haveLast = false;
      continue;
    }

    if (!detect_matrix || !frame.jpg || frame.len == 0) {
      if (frame.jpg) heap_caps_free(frame.jpg);
      continue;
    }

    if (!full_matrix || full_matrix->w != frame.width || full_matrix->h != frame.height) {
      if (full_matrix) dl_matrix3du_free(full_matrix);
      full_matrix = dl_matrix3du_alloc(1, frame.width, frame.height, 3);
    }

    bool facePresent = false;
    float bestCx = 0.0f;
    float bestCy = 0.0f;

    if (full_matrix && fmt2rgb888(frame.jpg, frame.len, frame.format, full_matrix->item)) {
      downscaleRgb888Nearest(full_matrix->item, frame.width, frame.height, detect_matrix->item, DETECT_W, DETECT_H);
      box_array_t *net_boxes = face_detect(detect_matrix, &mtmn_config);
      if (net_boxes) {
        facePresent = getBestBox(net_boxes, DETECT_W, DETECT_H, bestCx, bestCy);
        if (facePresent) {
          float embedding[128];
          if (tryGetFaceEmbedding(detect_matrix, net_boxes, embedding)) {
            bool stable = true;
            if (haveLast) {
              float dx = fabsf(bestCx - lastCx);
              float dy = fabsf(bestCy - lastCy);
              stable = dx <= BOX_STABILITY_MAX_CENTER_DELTA && dy <= BOX_STABILITY_MAX_CENTER_DELTA;
            }

            if (!stable) {
              consecutiveDetections = 1;
            } else {
              consecutiveDetections++;
            }

            haveLast = true;
            lastCx = bestCx;
            lastCy = bestCy;

            uint32_t now = millis();
            if (consecutiveDetections >= STABILITY_THRESHOLD) {
              if (!triggered || (now - lastEventMs) >= EVENT_COOLDOWN_MS) {
                triggered = true;
                lastEventMs = now;
                g_notifyFaceEvent = true;

                camera_fb_t fakeFb = {};
                fakeFb.buf = frame.jpg;
                fakeFb.len = frame.len;
                fakeFb.width = frame.width;
                fakeFb.height = frame.height;
                fakeFb.format = frame.format;
                sendFaceDetectionEvent(&fakeFb, embedding, 128);
              }
            }
          } else {
            facePresent = false;
          }
        }

        dl_lib_free(net_boxes->score);
        dl_lib_free(net_boxes->box);
        if (net_boxes->landmark != NULL) dl_lib_free(net_boxes->landmark);
        dl_lib_free(net_boxes);
      }
    }

    if (!facePresent) {
      consecutiveDetections = 0;
      triggered = false;
      haveLast = false;
    }

    if (frame.jpg) heap_caps_free(frame.jpg);
  }
}

void setupSecurityManager(int pirPin, const char* backendBaseUrl) {
  _pirPin = pirPin;
  pinMode(_pirPin, INPUT);
  g_backendBaseUrl = backendBaseUrl ? String(backendBaseUrl) : "";

  // Initialize face detection config (copied from boilerplate)
  mtmn_config.type = FAST;
  mtmn_config.min_face = 20;
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

  if (!g_detectQueue) {
    g_detectQueue = xQueueCreate(1, sizeof(DetectFrame));
  }
  if (!g_faceTaskHandle && g_detectQueue) {
    xTaskCreatePinnedToCore(
      faceDetectionTask,
      "FaceDetect",
      16384,
      NULL,
      1,
      &g_faceTaskHandle,
      1
    );
  }
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
  g_motionActive = _motionDetected;

  if (!_motionDetected) {
    return false;
  }

  if (!fb || !fb->buf || fb->len == 0 || !g_detectQueue) {
    return true;
  }

  uint32_t now = millis();
  if ((now - g_lastEnqueueMs) < DETECTION_INTERVAL_MS) {
    return true;
  }
  g_lastEnqueueMs = now;

  uint8_t* copyBuf = (uint8_t*)heap_caps_malloc(fb->len, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
  if (!copyBuf) {
    copyBuf = (uint8_t*)malloc(fb->len);
  }
  if (!copyBuf) {
    return true;
  }

  memcpy(copyBuf, fb->buf, fb->len);

  DetectFrame old = {};
  if (xQueueReceive(g_detectQueue, &old, 0) == pdTRUE) {
    if (old.jpg) heap_caps_free(old.jpg);
  }

  DetectFrame frame = {};
  frame.jpg = copyBuf;
  frame.len = fb->len;
  frame.width = fb->width;
  frame.height = fb->height;
  frame.format = fb->format;
  frame.capturedMs = now;

  if (xQueueSend(g_detectQueue, &frame, 0) != pdTRUE) {
    heap_caps_free(copyBuf);
  }

  return true;
}
