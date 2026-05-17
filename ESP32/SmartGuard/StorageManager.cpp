#include "StorageManager.h"
#include "SecurityManager.h"
#include <WiFi.h>
#include <SD_MMC.h>
#include <HTTPClient.h>

File currentVideo;
unsigned long segmentStartTime = 0;
const unsigned long SEGMENT_DURATION = 60000; // 1 minute
int currentSegmentIndex = 2;
bool isRecording = false;
bool isSDInitialized = false;
unsigned long triggerEndTime = 0;
bool motionActive = false;

enum class SyncState
{
  None,
  WaitForCurrentEnd,
  WaitForNextEnd
};

SyncState syncState = SyncState::None;

// We'll keep 3 segments: video_0.mjpeg, video_1.mjpeg, video_2.mjpeg
const char* filenames[] = {"/video_0.mjpeg", "/video_1.mjpeg", "/video_2.mjpeg"};

bool setupStorageManager() {
  if (!SD_MMC.begin("/sdcard", true)) { // Use 1-bit mode to free up pins 4, 12, 13
    Serial.println("SD Card Mount Failed. Storage functionality will be disabled.");
    isSDInitialized = false;
    return false;
  }
  uint8_t cardType = SD_MMC.cardType();
  if (cardType == CARD_NONE) {
    Serial.println("No SD card attached. Storage functionality will be disabled.");
    isSDInitialized = false;
    return false;
  }
  Serial.println("SD Card initialized.");
  isSDInitialized = true;
  return true;
}

void startNewSegment() {
  if (!isSDInitialized) return;
  
  if (currentVideo) {
    currentVideo.flush();
    currentVideo.close();
  }
  
  currentSegmentIndex = (currentSegmentIndex + 1) % 3;
  String path = filenames[currentSegmentIndex];
  
  // Delete old file if it exists
  if (SD_MMC.exists(path)) {
    SD_MMC.remove(path);
    if (SD_MMC.exists(path)) {
      SD_MMC.remove(path);
    }
  }

  currentVideo = SD_MMC.open(path, FILE_WRITE);
  if (!currentVideo) {
    Serial.println("Failed to open file for recording");
    isRecording = false;
  } else {
    Serial.println("Started recording: " + path);
    segmentStartTime = millis();
    isRecording = true;
  }
}

void handleRecording(bool motionDetected, bool notifyFaceEvent, const char* serverUrl) {
  if (!isSDInitialized) return;

  if (!isRecording) {
    startNewSegment();
  }

  if (notifyFaceEvent && syncState == SyncState::None) {
    syncState = SyncState::WaitForCurrentEnd;
  }

  if (motionDetected) {
    motionActive = true;
    triggerEndTime = millis() + SEGMENT_DURATION; // Record for 1 min after trigger stops
  } else {
    motionActive = false;
  }

  // Check if segment duration reached
  unsigned long now = millis();
  if (now - segmentStartTime >= SEGMENT_DURATION) {
    Serial.println("Segment finished. Rotating...");

    if (syncState == SyncState::WaitForCurrentEnd) {
      syncState = SyncState::WaitForNextEnd;
      startNewSegment();
      return;
    }

    if (syncState == SyncState::WaitForNextEnd) {
      syncFilesToBackend(serverUrl);
      syncState = SyncState::None;
      startNewSegment();
      return;
    }

    startNewSegment();
  }

  // Capture frame and save to SD (already done in main loop, we just use the frame if passed)
  // Wait, I should pass the frame to handleRecording
}

// Updated handleRecording to accept frame
void recordFrame(camera_fb_t* fb) {
  if (isSDInitialized && isRecording && currentVideo && fb) {
    currentVideo.write(fb->buf, fb->len);
  }
}

void syncFilesToBackend(const char* serverUrl) {
  if (!isSDInitialized || WiFi.status() != WL_CONNECTED) return;

  const String deviceToken = getDeviceToken();
  const int deviceId = getDeviceId();
  if (deviceToken == "" || deviceId <= 0) return;

  for (int i = 0; i < 3; i++) {
    String path = filenames[i];
    if (SD_MMC.exists(path)) {
      File file = SD_MMC.open(path);
      if (!file) continue;
      if (file.size() == 0) {
        file.close();
        continue;
      }

      Serial.println("Syncing " + path + " to backend...");
      Serial.println("Upload URL: " + String(serverUrl));
      Serial.printf("WiFi.status=%d RSSI=%d localIP=%s\n",
        (int)WiFi.status(),
        (int)WiFi.RSSI(),
        WiFi.localIP().toString().c_str());
      Serial.printf("File size: %u bytes\n", (unsigned int)file.size());

      HTTPClient http;
      bool beginOk = http.begin(serverUrl);
      if (!beginOk) {
        Serial.println("HTTP begin() failed");
        file.close();
        http.end();
        continue;
      }

      http.addHeader("Content-Type", "video/x-motion-jpeg");
      http.addHeader("X-Device-Id", String(deviceId));
      http.addHeader("X-Device-Token", deviceToken);
      
      int httpResponseCode = http.sendRequest("POST", &file, file.size());
      
      if (httpResponseCode == 200) {
        Serial.println("Sync successful: " + String(httpResponseCode));
        SD_MMC.remove(path); 
      } else {
        if (httpResponseCode < 0) {
          Serial.printf("Sync failed: %d (%s)\n", httpResponseCode, http.errorToString(httpResponseCode).c_str());
        } else {
          Serial.printf("Sync failed: HTTP %d\n", httpResponseCode);
          String body = http.getString();
          if (body.length() > 0) {
            Serial.println("Response body: " + body);
          }
        }
      }
      
      file.close();
      http.end();
    }
  }
}
