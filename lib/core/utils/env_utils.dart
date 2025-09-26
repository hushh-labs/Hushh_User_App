import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Utility class to get environment variables that works for both web and mobile
class EnvUtils {
  /// Get environment variable value
  /// For web: uses --dart-define values
  /// For mobile: uses .env file values
  static String get(String key, {String defaultValue = ''}) {
    if (kIsWeb) {
      // For web builds, use dart-define values
      return const String.fromEnvironment(key, defaultValue: '');
    } else {
      // For mobile builds, use dotenv
      return dotenv.env[key] ?? defaultValue;
    }
  }

  /// Get environment variable with default value
  static String getWithDefault(String key, String defaultValue) {
    final value = get(key);
    return value.isEmpty ? defaultValue : value;
  }
}
