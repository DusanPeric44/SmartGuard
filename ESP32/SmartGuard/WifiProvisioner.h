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
 * Returns the registration key (apiKey) received during provisioning.
 */
String getRegistrationKey();

#endif
