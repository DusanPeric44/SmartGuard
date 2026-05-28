#include "StreamManager.h"
#include <ArduinoJson.h>
#include "FlashManager.h"

WebSocketsClient webSocket;
bool isStreamingEnabled = false;
bool isHubConnected = false;

static const int FRAME_INTERVAL_MS = 50;

void sendFrame(camera_fb_t* fb) {
  if (!fb) return;

  // Send raw JPEG as a binary WebSocket frame (backend will base64-encode for clients)
  if (webSocket.isConnected()) {
    webSocket.sendBIN(fb->buf, fb->len);
  }
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("[Stream] Disconnected from WebSocket Bridge");
      if (length > 0) {
        Serial.printf("[Stream] Disconnect reason: %s\n", (char*)payload);
      }
      isHubConnected = false;
      isStreamingEnabled = false;
      flashOn();
      break;
    case WStype_ERROR:
      Serial.printf("[Stream] WebSocket Error: %s\n", (char*)payload);
      break;
    case WStype_CONNECTED:
      Serial.println("[Stream] Connected to WebSocket Bridge.");
      isHubConnected = true;
      flashOff();
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
  // Disable WiFi sleep for better performance and to prevent handshake timeouts
  WiFi.setSleep(false);
  
  // Use the parameters passed from SmartGuard.ino
  webSocket.begin(host, port, path);
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
}

void handleStream(camera_fb_t* fb) {
  webSocket.loop();

  static unsigned long lastHeartbeatMs = 0;
  const unsigned long HEARTBEAT_INTERVAL_MS = 10000;
  if (webSocket.isConnected()) {
    unsigned long now = millis();
    if (now - lastHeartbeatMs >= HEARTBEAT_INTERVAL_MS) {
      webSocket.sendTXT("HB");
      lastHeartbeatMs = now;
    }
  }

  static unsigned long lastFrameTime = 0;

  if (isStreamingEnabled && isHubConnected && fb) {
    if (millis() - lastFrameTime >= (unsigned long)FRAME_INTERVAL_MS) {
      sendFrame(fb);
      lastFrameTime = millis();
    }
  }
}
