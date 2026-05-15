#ifndef WIFI_PROVISIONER_H
#define WIFI_PROVISIONER_H

#include <WiFi.h>
#include <WebServer.h>

/**
 * Starts the WiFi provisioning process.
 * Opens an Access Point and a web server to receive credentials.
 */
void setupWifiProvisioning();

/**
 * Attempts to connect to WiFi using stored credentials.
 * Returns true if connected, false otherwise.
 */
bool connectToStoredWifi();

/**
 * Returns the registration key (apiKey) received during provisioning.
 */
String getRegistrationKey();

#endif
