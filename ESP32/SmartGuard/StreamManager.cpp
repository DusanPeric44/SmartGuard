#include "StreamManager.h"
#include <ArduinoJson.h>
#include <mbedtls/base64.h>

WebSocketsClient webSocket;
bool isStreamingEnabled = false;
bool isHubConnected = false;

void sendFrame(camera_fb_t* fb) {
  if (!fb) return;

  // Check if we have enough heap memory before allocating
  size_t freeHeap = ESP.getFreeHeap();
  if (freeHeap < 60000) { // Keep at least 60KB free for system stability
    Serial.println("[Stream] Memory low, skipping frame");
    return;
  }

  // Convert JPEG to Base64
  size_t outputLen;
  mbedtls_base64_encode(NULL, 0, &outputLen, fb->buf, fb->len);
  unsigned char* base64Buffer = (unsigned char*)malloc(outputLen + 1);
  
  if (!base64Buffer) {
    Serial.println("[Stream] Failed to allocate Base64 buffer!");
    return;
  }

  mbedtls_base64_encode(base64Buffer, outputLen + 1, &outputLen, fb->buf, fb->len);
  base64Buffer[outputLen] = '\0';

  // Send raw base64 frame via pure WebSocket
  if (webSocket.isConnected()) {
    webSocket.sendTXT((char*)base64Buffer);
  }
  
  free(base64Buffer);
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("[Stream] Disconnected from WebSocket Bridge");
      isHubConnected = false;
      isStreamingEnabled = false;
      break;
    case WStype_CONNECTED:
      Serial.println("[Stream] Connected to WebSocket Bridge.");
      isHubConnected = true;
      break;
    case WStype_TEXT:
      {
        String msg = String((const char*)payload, length);
        Serial.print("[Stream] Received Command: ");
        Serial.println(msg);
        
        // Parse simple JSON commands from server
        JsonDocument doc;
        DeserializationError error = deserializeJson(doc, msg);
        if (error) {
          Serial.print("[Stream] JSON parse error: ");
          Serial.println(error.c_str());
          return;
        }

        String target = doc["target"];
        if (target == "StartStream") {
          Serial.println("[Stream] Starting stream...");
          isStreamingEnabled = true;
        } else if (target == "StopStream") {
          Serial.println("[Stream] Stopping stream...");
          isStreamingEnabled = false;
        } else if (target == "MarkSafe") {
          int faceId = doc["arguments"][0];
          Serial.println("[Stream] Marking face ID safe: " + String(faceId));
          extern void markFaceAsSafe(int);
          markFaceAsSafe(faceId);
        } else if (target == "StartRecording") {
          Serial.println("[Stream] Remote command: Start Recording");
          // Add recording logic call if needed
        } else if (target == "StopRecording") {
          Serial.println("[Stream] Remote command: Stop Recording");
          // Add recording logic call if needed
        }
      }
      break;
  }
}

void setupStreamManager(const char* host, int port, const char* path) {
  // Use the parameters passed from SmartGuard.ino
  webSocket.begin(host, port, path);
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
}

void handleStream(camera_fb_t* fb) {
  webSocket.loop();

  static unsigned long lastFrameTime = 0;
  const int FRAME_INTERVAL = 100; // Limit to ~10 FPS to prevent crashing/congestion

  if (isStreamingEnabled && isHubConnected && fb) {
    if (millis() - lastFrameTime > FRAME_INTERVAL) {
      sendFrame(fb);
      lastFrameTime = millis();
    }
  }
}
