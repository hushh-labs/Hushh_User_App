// Navigation service abstract class

abstract class NavigationService {
  // Navigate to a specific route
  void navigateTo(String routeName, {Object? arguments});

  // Navigate and replace current route
  void navigateToReplacement(String routeName, {Object? arguments});

  // Navigate and clear all previous routes
  void navigateToAndClear(String routeName, {Object? arguments});

  // Go back
  void goBack();

  // Check if can go back
  bool canGoBack();

  // Get current route name
  String? getCurrentRoute();
}
