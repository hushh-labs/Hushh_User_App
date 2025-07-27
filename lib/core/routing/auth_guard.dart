// Authentication route guard
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    // Temporarily allow all routes for development
    // TODO: Implement proper authentication logic later
    return null;

    // Original logic (commented out for now):
    // final isAuthenticated = FirebaseUtils.isUserAuthenticated();
    // final isAuthRoute =
    //     state.matchedLocation == RoutePaths.mainAuth ||
    //     state.matchedLocation == RoutePaths.login ||
    //     state.matchedLocation == RoutePaths.register;

    // // If user is not authenticated and trying to access protected route
    // if (!isAuthenticated && !isAuthRoute) {
    //   return RoutePaths.mainAuth;
    // }

    // // If user is authenticated and trying to access auth routes
    // if (isAuthenticated && isAuthRoute) {
    //   return RoutePaths.home;
    // }

    // // No redirect needed
    // return null;
  }
}
