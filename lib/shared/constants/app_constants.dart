// Shared app constants
class AppConstants {
  // App information
  static const String appName = 'Hushh User App';
  static const String appVersion = '1.0.0';

  // API constants
  static const int apiTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;

  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 4.0;

  // Animation constants
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Validation constants
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Cache constants
  static const Duration defaultCacheDuration = Duration(hours: 1);
  static const Duration longCacheDuration = Duration(days: 7);

  // Pagination constants
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
