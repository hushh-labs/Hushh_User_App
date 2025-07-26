// Firebase constants and configuration
import '../../shared/constants/firestore_constants.dart';

class FirebaseConstants {
  // Use FirestoreCollections for collection names
  static const String usersCollection = FirestoreCollections.users;
  static const String authCollection = FirestoreCollections.auth;
  
  // Use FirestoreFields for field names
  static const String userIdField = FirestoreFields.userId;
  static const String emailField = FirestoreFields.email;
  static const String nameField = FirestoreFields.name;
  static const String createdAtField = FirestoreFields.createdAt;
  static const String updatedAtField = FirestoreFields.updatedAt;
  
  // Firebase auth error messages
  static const String userNotFound = 'User not found';
  static const String wrongPassword = 'Wrong password';
  static const String emailAlreadyInUse = 'Email already in use';
  static const String weakPassword = 'Password is too weak';
  static const String invalidEmail = 'Invalid email address';
  static const String networkError = 'Network error occurred';
  
  // Firebase configuration
  static const String defaultErrorMessage = 'An error occurred. Please try again.';
}
