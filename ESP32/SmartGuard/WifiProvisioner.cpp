#include "WifiProvisioner.h"
#include <Preferences.h>
#include <esp_system.h>
#include "FlashManager.h"

WebServer server(80);
Preferences wifiPrefs;
bool provisioned = false;
String ssid_to_connect = "";
String pass_to_connect = "";
String registration_key = "";

void saveCredentials(String ssid, String pass, String regKey) {
  wifiPrefs.begin("wifi-config", false);
  wifiPrefs.putString("ssid", ssid);
  wifiPrefs.putString("password", pass);
  wifiPrefs.putString("reg_key", regKey);
  wifiPrefs.end();
  Serial.println("Credentials saved to Preferences.");
}

bool connectToStoredWifi() {
  wifiPrefs.begin("wifi-config", true);
  ssid_to_connect = wifiPrefs.getString("ssid", "");
  pass_to_connect = wifiPrefs.getString("password", "");
  registration_key = wifiPrefs.getString("reg_key", "");
  wifiPrefs.end();

  if (ssid_to_connect == "") {
    Serial.println("No stored WiFi credentials found.");
    return false;
  }

  Serial.println("Attempting to connect to stored WiFi: " + ssid_to_connect);
  WiFi.begin(ssid_to_connect.c_str(), pass_to_connect.c_str());

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected from storage!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    flashOn();
    return true;
  } else {
    Serial.println("\nFailed to connect using stored credentials.");
    return false;
  }
}

void handleProvision() {
  if (server.hasArg("ssid") && server.hasArg("password") && server.hasArg("apiKey")) {
    ssid_to_connect = server.arg("ssid");
    pass_to_connect = server.arg("password");
    registration_key = server.arg("apiKey");
    
    saveCredentials(ssid_to_connect, pass_to_connect, registration_key);
    
    server.send(200, "text/plain", "Credentials received and saved. Connecting...");
    provisioned = true;
    flashOn();
    Serial.println("Received SSID: " + ssid_to_connect);
    Serial.println("Received Registration Key: ****");
  } else {
    server.send(400, "text/plain", "SSID, Password and apiKey required");
  }
}

String getRegistrationKey() {
  return registration_key;
}

String getDeviceApPassword() {
  wifiPrefs.begin("wifi-config", false);
  String pass = wifiPrefs.getString("ap_pass", "");

  if (pass.length() < 8) {
    uint8_t randomBytes[6];
    for (int i = 0; i < 6; i++) {
      randomBytes[i] = (uint8_t)(esp_random() & 0xFF);
    }

    char hex[13];
    snprintf(hex, sizeof(hex), "%02x%02x%02x%02x%02x%02x",
             randomBytes[0], randomBytes[1], randomBytes[2],
             randomBytes[3], randomBytes[4], randomBytes[5]);

    pass = "sg" + String(hex);
    wifiPrefs.putString("ap_pass", pass);
  }

  wifiPrefs.end();
  return pass;
}

void setupWifiProvisioning() {
  while (true) {
    Serial.println("Starting WiFi Provisioning...");

    String apPassword = getDeviceApPassword();
    WiFi.softAP("ESP32-SmartCam-AP", apPassword.c_str());
    Serial.println("Provisioning AP password: " + apPassword);
    IPAddress IP = WiFi.softAPIP();
    Serial.print("AP IP address: ");
    Serial.println(IP);

    server.on("/provision", HTTP_POST, handleProvision);
    server.begin();
    Serial.println("Provisioning server started. Waiting for Flutter app...");

    provisioned = false;
    flashBlink(1000);
    while (!provisioned) {
      server.handleClient();
      flashUpdate();
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
