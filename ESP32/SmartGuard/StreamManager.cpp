#include "StreamManager.h"
#include <ArduinoJson.h>
#include <mbedtls/base64.h>

WebSocketsClient webSocket;
bool isStreamingEnabled = false;
bool isHubConnected = false;

// SignalR message terminator
const char RECORD_SEPARATOR = 0x1E;

void sendSignalRHandshake() {
  String handshake = "{\"protocol\":\"json\",\"version\":1}";
  handshake += RECORD_SEPARATOR;
  webSocket.sendTXT(handshake);
}

void sendFrame(camera_fb_t* fb) {
  if (!fb) return;

  // Convert JPEG to Base64
  size_t outputLen;
  mbedtls_base64_encode(NULL, 0, &outputLen, fb->buf, fb->len);
  unsigned char* base64Buffer = (unsigned char*)malloc(outputLen + 1);
  if (!base64Buffer) return;

  mbedtls_base64_encode(base64Buffer, outputLen + 1, &outputLen, fb->buf, fb->len);
  base64Buffer[outputLen] = '\0';

  // Prepare SignalR message
  // Method: "UploadFrame", Arguments: [base64_string]
  JsonDocument doc; 
  doc["type"] = 1;
  doc["target"] = "UploadFrame";
  JsonArray args = doc["arguments"].to<JsonArray>();
  args.add((char*)base64Buffer);

  String msg;
  serializeJson(doc, msg);
  msg += RECORD_SEPARATOR;

  webSocket.sendTXT(msg);
  free(base64Buffer);
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("[Stream] Disconnected from SignalR Hub");
      isHubConnected = false;
      isStreamingEnabled = false;
      break;
    case WStype_CONNECTED:
      Serial.println("[Stream] Connected to Hub. Sending handshake...");
      sendSignalRHandshake();
      break;
    case WStype_TEXT:
      String msg = String((char*)payload);
      if (msg.endsWith(String(RECORD_SEPARATOR))) {
        msg.remove(msg.length() - 1);
      }
      
      Serial.println("[Stream] Received: " + msg);
      
      // Parse SignalR messages
      JsonDocument doc;
      DeserializationError error = deserializeJson(doc, msg);
      if (error) return;

      // Check for handshake response (empty object)
      if (doc.as<JsonObject>().size() == 0 && !isHubConnected) {
        isHubConnected = true;
        Serial.println("[Stream] Handshake successful");
        return;
      }

      // Check for method calls from Hub
      if (doc["type"] == 1) { // Invocation
        String target = doc["target"];
        if (target == "StartStream") {
          Serial.println("[Stream] Remote user connected. Starting stream...");
          isStreamingEnabled = true;
        } else if (target == "StopStream") {
          Serial.println("[Stream] Stopping stream...");
          isStreamingEnabled = false;
        } else if (target == "MarkSafe") {
          int faceId = doc["arguments"][0];
          Serial.println("[Stream] Received MarkSafe for ID: " + String(faceId));
          // We'll call a function in SecurityManager
          extern void markFaceAsSafe(int);
          markFaceAsSafe(faceId);
        }
      }
      break;
  }
}

void setupStreamManager(const char* host, int port, const char* path) {
  webSocket.begin(host, port, path);
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
}

void handleStream() {
  webSocket.loop();

  if (isStreamingEnabled && isHubConnected) {
    camera_fb_t* fb = esp_camera_fb_get();
    if (fb) {
      sendFrame(fb);
      esp_camera_fb_return(fb);
    }
  }
}
