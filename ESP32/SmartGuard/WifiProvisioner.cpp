#include "WifiProvisioner.h"

WebServer server(80);
bool provisioned = false;
String ssid_to_connect = "";
String pass_to_connect = "";
String registration_key = "";

void handleProvision() {
  if (server.hasArg("ssid") && server.hasArg("password") && server.hasArg("apiKey")) {
    ssid_to_connect = server.arg("ssid");
    pass_to_connect = server.arg("password");
    registration_key = server.arg("apiKey");
    server.send(200, "text/plain", "Credentials received. Connecting...");
    provisioned = true;
    Serial.println("Received SSID: " + ssid_to_connect);
    Serial.println("Received Registration Key: " + registration_key);
  } else {
    server.send(400, "text/plain", "SSID, Password and apiKey required");
  }
}

String getRegistrationKey() {
  return registration_key;
}

void setupWifiProvisioning() {
  while (true) {
    Serial.println("Starting WiFi Provisioning...");
    
    WiFi.softAP("ESP32-SmartCam-AP", "password123"); 
    IPAddress IP = WiFi.softAPIP();
    Serial.print("AP IP address: ");
    Serial.println(IP);

    server.on("/provision", HTTP_POST, handleProvision);
    server.begin();
    Serial.println("Provisioning server started. Waiting for Flutter app...");

    provisioned = false;
    while (!provisioned) {
      server.handleClient();
      delay(10);
    }

    // Once provisioned, cleanup and connect
    server.stop();
    WiFi.softAPdisconnect(true);
    Serial.println("Shutting down AP and connecting to WiFi...");

    WiFi.begin(ssid_to_connect.c_str(), pass_to_connect.c_str());

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
      delay(500);
      Serial.print(".");
      attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nWiFi connected!");
      Serial.print("IP address: ");
      Serial.println(WiFi.localIP());
      break; // Exit the loop on success
    } else {
      Serial.println("\nFailed to connect. Restarting provisioning...");
    }
  }
}
