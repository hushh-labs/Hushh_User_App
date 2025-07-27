import 'package:flutter/material.dart';

class Utils {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  static void showAlertDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s-]+$').hasMatch(phone);
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// Development helper to generate test phone numbers
/// This helps avoid "too-many-requests" errors during development
class DevelopmentHelper {
  static bool get isDevelopment =>
      const bool.fromEnvironment('dart.vm.product') == false;

  /// Generate a test phone number for development
  /// This helps avoid rate limiting issues during testing
  static String generateTestPhoneNumber() {
    // Generate a random phone number for testing
    final random = DateTime.now().millisecondsSinceEpoch;
    final lastDigits = (random % 9999).toString().padLeft(4, '0');
    return '+91843144$lastDigits';
  }

  /// Check if the current phone number is a test number
  static bool isTestPhoneNumber(String phoneNumber) {
    return phoneNumber.startsWith('+91843144') && phoneNumber.length == 13;
  }

  /// Get development tips for common Firebase errors
  static String getDevelopmentTip(String errorCode) {
    switch (errorCode) {
      case 'too-many-requests':
        return '💡 Development Tip: Try using a different phone number or wait 5-10 minutes. You can also use the test number generator.';
      case 'invalid-phone-number':
        return '💡 Development Tip: Make sure the phone number includes the country code (e.g., +91 for India).';
      case 'quota-exceeded':
        return '💡 Development Tip: Firebase SMS quota exceeded. Try again later or use a different phone number.';
      default:
        return '💡 Development Tip: Check your Firebase configuration and network connection.';
    }
  }
}
