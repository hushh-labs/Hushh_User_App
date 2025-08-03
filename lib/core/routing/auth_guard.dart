// Authentication route guard
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/firebase_utils.dart';
import 'route_paths.dart';
import '../../shared/utils/app_local_storage.dart';

class AuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = FirebaseUtils.isUserAuthenticated();
    final isGuestMode = AppLocalStorage.isGuestMode;
    final isAuthRoute =
        state.matchedLocation == RoutePaths.mainAuth ||
        state.matchedLocation == RoutePaths.phoneInput ||
        state.matchedLocation == RoutePaths.otpVerification;

    // Special routes that require authentication but should not auto-redirect to discover
    final isAuthenticatedOnlyRoute =
        state.matchedLocation == RoutePaths.createFirstCard ||
        state.matchedLocation == RoutePaths.cardCreatedSuccess ||
        state.matchedLocation == RoutePaths.videoRecording;

    // If user is not authenticated and not in guest mode and trying to access protected route
    if (!isAuthenticated &&
        !isGuestMode &&
        !isAuthRoute &&
        !isAuthenticatedOnlyRoute) {
      return RoutePaths.mainAuth;
    }

    // If user is authenticated and trying to access auth routes (but not authenticated-only routes)
    if (isAuthenticated && isAuthRoute) {
      return RoutePaths.discover;
    }

    // No redirect needed
    return null;
  }
}
