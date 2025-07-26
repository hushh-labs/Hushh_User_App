// Navigation helper for easy navigation from anywhere in the app
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';

class NavigationHelper {
  // Navigate to login page
  static void goToLogin(BuildContext context) {
    context.goNamed(RouteNames.login);
  }

  // Navigate to register page
  static void goToRegister(BuildContext context) {
    context.goNamed(RouteNames.register);
  }

  // Navigate to home page
  static void goToHome(BuildContext context) {
    context.goNamed(RouteNames.home);
  }

  // Navigate to profile page
  static void goToProfile(BuildContext context) {
    context.pushNamed(RouteNames.profile);
  }

  // Navigate to settings page
  static void goToSettings(BuildContext context) {
    context.pushNamed(RouteNames.settings);
  }

  // Navigate to notifications page
  static void goToNotifications(BuildContext context) {
    context.pushNamed(RouteNames.notifications);
  }

  // Go back
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  // Navigate with arguments
  static void goToWithArguments(
    BuildContext context,
    String routeName,
    Object arguments,
  ) {
    context.pushNamed(routeName, extra: arguments);
  }

  // Replace current route
  static void replaceRoute(BuildContext context, String routeName) {
    context.pushReplacementNamed(routeName);
  }

  // Clear all routes and navigate
  static void clearAndNavigate(BuildContext context, String routeName) {
    context.goNamed(routeName);
  }
}
