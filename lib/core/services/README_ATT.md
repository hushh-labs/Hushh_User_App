# App Tracking Transparency (ATT) Implementation

This document explains how the App Tracking Transparency (ATT) feature is implemented in the Hushh User App.

## Overview

The ATT implementation allows the app to request permission from iOS users to track their activity across other apps and websites. This is required by Apple for apps that want to access the IDFA (Identifier for Advertisers).

## Files Modified

1. **pubspec.yaml** - Added `app_tracking_transparency` dependency
2. **ios/Runner/Info.plist** - Added `NSUserTrackingUsageDescription` permission
3. **lib/main.dart** - Integrated ATT request on app startup
4. **lib/core/services/app_tracking_transparency_service.dart** - Created ATT service

## How It Works

### App Startup
The ATT prompt is automatically requested when the app starts up in the `main()` function, before the main app is initialized. This ensures the prompt appears early in the user experience.

### Service Usage
The `AppTrackingTransparencyService` provides several methods:

- `requestTrackingAuthorization()` - Requests permission from the user
- `getTrackingStatus()` - Gets current tracking status
- `getAdvertisingIdentifier()` - Gets IDFA if authorized
- `isTrackingAuthorized()` - Checks if tracking is authorized

### Example Usage

```dart
import 'package:hushh_user_app/core/services/app_tracking_transparency_service.dart';

// Get the service instance
final attService = AppTrackingTransparencyService();

// Check if tracking is authorized
bool isAuthorized = await attService.isTrackingAuthorized();

// Get the advertising identifier (IDFA) if authorized
String? idfa = await attService.getAdvertisingIdentifier();

// Get current tracking status
TrackingStatus status = await attService.getTrackingStatus();
```

## Tracking Status Values

- `TrackingStatus.authorized` - User granted permission
- `TrackingStatus.denied` - User denied permission
- `TrackingStatus.restricted` - System restricted tracking
- `TrackingStatus.notDetermined` - User hasn't been asked yet
- `TrackingStatus.notSupported` - Not supported on this device

## Testing

To test the ATT implementation:

1. **iOS Simulator**: The prompt will appear on first launch
2. **iOS Device**: The prompt will appear on first launch
3. **Reset Settings**: To test again, go to Settings > Privacy & Security > Tracking and reset the app's permission

## Important Notes

- The ATT prompt only appears on iOS devices
- The prompt is shown only once per app installation
- Users can change their preference in iOS Settings
- The IDFA is only available when tracking is authorized
- Always handle the case where tracking is denied gracefully

## Privacy Considerations

- Only request tracking permission if your app actually needs it
- Provide clear explanation of why tracking is needed
- Respect user's choice and provide alternative experiences when tracking is denied
- Don't block app functionality if tracking is denied
