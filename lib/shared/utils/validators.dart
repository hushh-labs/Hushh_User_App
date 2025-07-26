// Shared validators
import '../constants/app_constants.dart';

class Validators {
  // Email validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password validation
  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength &&
        password.length <= AppConstants.maxPasswordLength &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  // Name validation
  static bool isValidName(String name) {
    return name.length >= AppConstants.minNameLength &&
        name.length <= AppConstants.maxNameLength &&
        RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  // Phone validation
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phone);
  }

  // URL validation
  static bool isValidUrl(String url) {
    return RegExp(r'^https?:\/\/[\w\-\.]+(:\d+)?(\/.*)?$').hasMatch(url);
  }

  // Get password strength
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return 'Empty';

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    switch (score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
      case 3:
        return 'Medium';
      case 4:
      case 5:
        return 'Strong';
      default:
        return 'Very Strong';
    }
  }
}
