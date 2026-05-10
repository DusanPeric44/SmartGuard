#ifndef SECURITY_MANAGER_H
#define SECURITY_MANAGER_H

#include "esp_camera.h"
#include <ArduinoJson.h>

/**
 * Initializes the PIR sensor and face recognition components.
 */
void setupSecurityManager(int pirPin);

/**
 * Checks PIR sensor and performs face detection if triggered.
 * Returns true if motion is detected.
 */
bool checkSecurity(camera_fb_t* fb);

/**
 * Marks a face ID as safe.
 */
void markFaceAsSafe(int faceId);

/**
 * Checks if a face ID is safe.
 */
bool isFaceSafe(int faceId);

/**
 * Registers the device with the backend using the provided registration key.
 * Stores the returned device token in NVS.
 */
bool registerDevice(const char* serverUrl, const char* registrationKey);

/**
 * Retrieves the device token from NVS.
 */
String getDeviceToken();

#endif
