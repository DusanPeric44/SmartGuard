#ifndef SECURITY_MANAGER_H
#define SECURITY_MANAGER_H

#include "esp_camera.h"
#include <ArduinoJson.h>

/**
 * Initializes the PIR sensor and face recognition components.
 */
void setupSecurityManager(int pirPin, const char* backendBaseUrl);

/**
 * Checks PIR sensor and performs face detection if triggered.
 * Returns true if motion is detected.
 */
bool checkSecurity(camera_fb_t* fb);

/**
 * Returns true once when the face sequence reaches the notify condition.
 */
bool consumeNotifyFaceEvent();

/**
 * Returns true once when a motion event was successfully notified to backend.
 */
bool consumeNotifyMotionEvent();

/**
 * Registers the device with the backend using the provided registration key.
 * Stores the returned device token in NVS.
 */
bool registerDevice(const char* serverUrl, const char* registrationKey);

/**
 * Retrieves the device token from NVS.
 */
String getDeviceToken();

/**
 * Retrieves the device id from NVS.
 */
int getDeviceId();

#endif
