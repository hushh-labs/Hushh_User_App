import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../entities/user_card.dart';

abstract class AuthRepository {
  // Phone authentication
  Future<void> sendPhoneOtp(
    String phoneNumber, {
    Function(String phoneNumber)? onOtpSent,
  });
  Future<firebase_auth.UserCredential> verifyPhoneOtp(
    String phoneNumber,
    String otp,
  );

  // Email authentication
  Future<void> sendEmailOtp(String email);
  Future<firebase_auth.UserCredential> verifyEmailOtp(String email, String otp);

  // User management
  Future<firebase_auth.User?> getCurrentUser();
  Future<void> signOut();
  Stream<firebase_auth.User?> get authStateChanges;

  // User card management
  Future<UserCard?> getUserCard(String userId);
  Future<void> createUserCard(UserCard userCard);
  Future<void> updateUserCard(UserCard userCard);
  Future<bool> doesUserCardExist(String userId);

  // User data management
  Future<void> createUserData(String userId, Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData(String userId);
  Future<void> updateUserData(String userId, Map<String, dynamic> userData);
}
