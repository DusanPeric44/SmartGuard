#ifndef STORAGE_MANAGER_H
#define STORAGE_MANAGER_H

#include "esp_camera.h"
#include <SD.h>
#include <FS.h>

/**
 * Initializes the SD card and storage logic.
 */
bool setupStorageManager();

/**
 * Handles the loop recording logic. 
 */
void handleRecording(bool motionDetected, bool notifyFaceEvent, const char* serverUrl);

/**
 * Saves a frame to the current video segment.
 */
void recordFrame(camera_fb_t* fb);

/**
 * Starts a new 1-minute recording segment.
 */
void startNewSegment();

/**
 * Syncs completed videos to the .NET backend.
 */
void syncFilesToBackend(const char* serverUrl);

#endif
