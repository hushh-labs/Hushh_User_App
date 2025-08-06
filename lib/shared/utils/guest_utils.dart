import 'package:flutter/material.dart';
import 'guest_access_control.dart';
import 'app_local_storage.dart';

class GuestUtils {
  /// Execute a function with guest access check
  /// If user is in guest mode, shows guest access popup
  /// If user is authenticated, executes the provided function
  static void executeWithGuestCheck(
    BuildContext context,
    String featureName,
    VoidCallback onExecute,
  ) {
    // Check if user is in guest mode
    if (AppLocalStorage.isGuestMode) {
      // Show guest access popup
      GuestAccessControl.showGuestAccessPopup(
        context,
        featureName: featureName,
      );
    } else {
      // Execute the function
      onExecute();
    }
  }

  /// Check if user is in guest mode
  static bool get isGuestMode => AppLocalStorage.isGuestMode;

  /// Check if user is authenticated
  static bool get isAuthenticated => !AppLocalStorage.isGuestMode;
}
