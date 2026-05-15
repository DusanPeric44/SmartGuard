# Plan: Implement Device Provisioning for HomeOwner

This plan outlines the steps to enable `HomeOwner` login and implement the device provisioning (Add New Device) flow in the SmartGuard Desktop application, while restricting device management access to HomeOwners only.

## 1. Analysis of Current State
- **Roles**: `admin`, `homeowner`, and `viewer` are defined.
- **Access Control**: The Desktop app currently restricts access to `admin` users only in `app_router.dart`.
- **Infrastructure**: The backend provides `/api/auth/registration-key`. The ESP32 expects a POST to `http://192.168.4.1/provision`.
- **Device Management**: `DeviceListViewModel` and `DevicesScreen` exist. Currently, they are accessible to Admins.

## 2. Proposed Changes

### Phase 1: Authentication & Authorization
- **[token_store.dart](file:///c:/Users/Page/source/fitRepos/SmartGuard/Desktop/smartguard_flutter/lib/core/auth/token_store.dart)**
    - Add `getRegistrationKey` and `setRegistrationKey` to `TokenStore` interface and implementations.
- **[auth_repository.dart](file:///c:/Users/Page/source/fitRepos/SmartGuard/Desktop/smartguard_flutter/lib/core/auth/auth_repository.dart)**
    - Add `fetchRegistrationKey()` to retrieve the key from `/auth/registration-key`.
- **[auth_controller.dart](file:///c:/Users/Page/source/fitRepos/SmartGuard/Desktop/smartguard_flutter/lib/core/auth/auth_controller.dart)**
    - Update `init` and `login` to fetch and store the `registrationKey` if the user role is `homeowner`.
- **[app_router.dart](file:///c:/Users/Page/source/fitRepos/SmartGuard/Desktop/smartguard_flutter/lib/app/router/app_router.dart)**
    - Update redirect logic to allow `UserRole.admin` and `UserRole.homeowner`.
    - **Restrict `/devices` Route**: Update the route definition for `/devices` to only allow `UserRole.homeowner`. Redirect `Admin` to `/dashboard` if they try to access it.
- **[app_nav_items.dart](file:///c:/Users/Page/source/fitRepos/SmartGuard/Desktop/smartguard_flutter/lib/app/navigation/app_nav_items.dart)**
    - Update navigation logic in `AppShell` or filter `appNavItems` to hide "Device Management" from the sidebar for `Admin`.

### Phase 2: ViewModel Implementation
- **[device_list_view_model.dart](file:///c:/Users/Page/source/fitRepos/SmartGuard/Desktop/smartguard_flutter/lib/features/devices/viewmodel/device_list_view_model.dart)**
    - Add state variables: `bool isProvisioning`, `String? provisioningStatus`.
    - Add `provisionDevice(String ssid, String password)` method:
        1. Fetch `registrationKey` from `AuthController`.
        2. Send POST request to `http://192.168.4.1/provision` with `ssid`, `password`, and `registrationKey`.
        3. **Dynamic Polling**: Poll the device list every 2-3 seconds until a new device appears or 30 seconds elapse.
        4. Return the new device ID or null.

### Phase 3: UI Implementation
- **[devices_screen.dart](file:///c:/Users/Page/source/fitRepos/SmartGuard/Desktop/smartguard_flutter/lib/features/devices/devices_screen.dart)**
    - Update `_FiltersCard` to include an "Add New Device" button (visible for `HomeOwner`).
    - Implement `_ProvisioningWizard` dialog with steps:
        1. **Instructions**: Connect to `ESP32-SmartCam-AP`. Provide a button to open WiFi settings.
        2. **WiFi Credentials**: Form for SSID and Password.
        3. **Provisioning**: Show progress during polling.
        4. **Success/Failure**: Redirect to device details or show retry.

## 3. Assumptions & Decisions
- **WiFi Settings**: On Windows, we will attempt to open WiFi settings using `start ms-settings:network-wifi`.
- **ESP32 IP**: We assume the ESP32 Access Point uses the standard `192.168.4.1` IP.
- **Redirection**: After successful provisioning, the app will navigate to `/devices/:deviceId`.
