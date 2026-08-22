#ifndef STREAM_MANAGER_H
#define STREAM_MANAGER_H

#include "esp_camera.h"
#include <WiFi.h>
#include <WebSocketsClient.h>

/**
 * Initializes the SignalR connection and streaming logic.
 */
void setupStreamManager(const char* host, int port, const char* path, const char* extraHeaders = nullptr);

/**
 * Handles the background tasks for streaming.
 */
void handleStream(camera_fb_t* fb);

/**
 * Starts streaming if a user is connected.
 */
void startStreaming();

/**
 * Stops streaming.
 */
void stopStreaming();

#endif
