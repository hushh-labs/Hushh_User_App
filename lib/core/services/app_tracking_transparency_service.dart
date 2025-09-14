import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// Service to handle App Tracking Transparency (ATT) requests on iOS
class AppTrackingTransparencyService {
  static final AppTrackingTransparencyService _instance =
      AppTrackingTransparencyService._internal();

  factory AppTrackingTransparencyService() => _instance;

  AppTrackingTransparencyService._internal();

  /// Request tracking authorization from the user
  /// This should be called early in the app lifecycle, ideally on app startup
  Future<TrackingStatus> requestTrackingAuthorization() async {
    // Only request on iOS devices
    if (!Platform.isIOS) {
      debugPrint('🔒 [ATT] Not iOS platform, skipping ATT request');
      return TrackingStatus.notSupported;
    }

    try {
      debugPrint('🔒 [ATT] Requesting tracking authorization...');

      // Check current status first
      final currentStatus =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('🔒 [ATT] Current tracking status: $currentStatus');

      // If already authorized or denied, return current status
      if (currentStatus == TrackingStatus.authorized ||
          currentStatus == TrackingStatus.denied) {
        debugPrint('🔒 [ATT] Tracking already $currentStatus');
        return currentStatus;
      }

      // Request authorization
      final status =
          await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('🔒 [ATT] Tracking authorization result: $status');

      // Log the result for analytics/debugging
      _logTrackingResult(status);

      return status;
    } catch (e) {
      debugPrint('❌ [ATT] Error requesting tracking authorization: $e');
      return TrackingStatus.notSupported;
    }
  }

  /// Get the current tracking authorization status
  Future<TrackingStatus> getTrackingStatus() async {
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('🔒 [ATT] Current tracking status: $status');
      return status;
    } catch (e) {
      debugPrint('❌ [ATT] Error getting tracking status: $e');
      return TrackingStatus.notSupported;
    }
  }

  /// Get the advertising identifier (IDFA) if tracking is authorized
  Future<String?> getAdvertisingIdentifier() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final status = await getTrackingStatus();
      if (status == TrackingStatus.authorized) {
        final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
        debugPrint(
          '🔒 [ATT] IDFA: ${idfa.isNotEmpty ? "Available" : "Not available"}',
        );
        return idfa.isNotEmpty ? idfa : null;
      } else {
        debugPrint('🔒 [ATT] Tracking not authorized, IDFA not available');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [ATT] Error getting advertising identifier: $e');
      return null;
    }
  }

  /// Log tracking result for analytics/debugging purposes
  void _logTrackingResult(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.authorized:
        debugPrint('✅ [ATT] User authorized tracking - IDFA available');
        break;
      case TrackingStatus.denied:
        debugPrint('❌ [ATT] User denied tracking - IDFA not available');
        break;
      case TrackingStatus.restricted:
        debugPrint(
          '⚠️ [ATT] Tracking restricted by system - IDFA not available',
        );
        break;
      case TrackingStatus.notDetermined:
        debugPrint('❓ [ATT] Tracking status not determined');
        break;
      case TrackingStatus.notSupported:
        debugPrint('🚫 [ATT] Tracking not supported on this device');
        break;
    }
  }

  /// Check if tracking is authorized
  Future<bool> isTrackingAuthorized() async {
    final status = await getTrackingStatus();
    return status == TrackingStatus.authorized;
  }
}
