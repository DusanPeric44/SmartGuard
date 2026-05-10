#include "StorageManager.h"
#include <SD_MMC.h>
#include <HTTPClient.h>

File currentVideo;
unsigned long segmentStartTime = 0;
const unsigned long SEGMENT_DURATION = 60000; // 1 minute
int currentSegmentIndex = 0;
bool isRecording = false;
bool isSDInitialized = false;
unsigned long triggerEndTime = 0;
bool motionActive = false;

// We'll keep 2 segments: video_0.mjpeg and video_1.mjpeg
const char* filenames[] = {"/video_0.mjpeg", "/video_1.mjpeg"};

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
  
  if (currentVideo) currentVideo.close();
  
  currentSegmentIndex = (currentSegmentIndex + 1) % 2;
  String path = filenames[currentSegmentIndex];
  
  // Delete old file if it exists
  if (SD_MMC.exists(path)) {
    SD_MMC.remove(path);
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

void handleRecording(bool isTriggered) {
  if (!isSDInitialized) return;

  if (!isRecording) {
    startNewSegment();
  }

  if (isTriggered) {
    motionActive = true;
    triggerEndTime = millis() + SEGMENT_DURATION; // Record for 1 min after trigger stops
  } else {
    motionActive = false;
  }

  // Check if segment duration reached
  unsigned long now = millis();
  if (now - segmentStartTime >= SEGMENT_DURATION) {
    // If motion was active recently, we keep recording in a new segment
    // otherwise we just rotate as usual.
    Serial.println("Segment finished. Rotating...");
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

  for (int i = 0; i < 2; i++) {
    String path = filenames[i];
    if (SD_MMC.exists(path)) {
      Serial.println("Syncing " + path + " to backend...");
      
      File file = SD_MMC.open(path);
      if (!file) continue;

      HTTPClient http;
      http.begin(serverUrl);
      http.addHeader("Content-Type", "video/x-motion-jpeg");
      
      int httpResponseCode = http.sendRequest("POST", &file, file.size());
      
      if (httpResponseCode > 0) {
        Serial.println("Sync successful: " + String(httpResponseCode));
        // Optionally delete after sync if the user wants
        // SD_MMC.remove(path); 
      } else {
        Serial.println("Sync failed: " + String(httpResponseCode));
      }
      
      file.close();
      http.end();
    }
  }
}
