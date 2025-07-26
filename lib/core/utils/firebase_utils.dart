// Firebase utility functions
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_constants.dart';

class FirebaseUtils {
  // Convert Firebase User to UserModel
  static Map<String, dynamic> userToMap(User user) {
    return {
      FirebaseConstants.userIdField: user.uid,
      FirebaseConstants.emailField: user.email,
      FirebaseConstants.nameField: user.displayName ?? '',
      FirebaseConstants.createdAtField: FieldValue.serverTimestamp(),
      FirebaseConstants.updatedAtField: FieldValue.serverTimestamp(),
    };
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  static bool isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  // Get error message from Firebase exception
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return FirebaseConstants.defaultErrorMessage;
  }

  // Check if user is authenticated
  static bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Get current user email
  static String? getCurrentUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }
}
