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

  // Supabase user card management (for dual storage)
  Future<void> createUserCardInSupabase(UserCard userCard);
  Future<UserCard?> getUserCardFromSupabase(String userId);
  Future<void> updateUserCardInSupabase(UserCard userCard);
  Future<bool> doesUserCardExistInSupabase(String userId);

  // Supabase user data management (for additional fields like phone number)
  Future<void> createUserDataInSupabase(
    String userId,
    Map<String, dynamic> userData,
  );
  Future<Map<String, dynamic>?> getUserDataFromSupabase(String userId);
  Future<void> updateUserDataInSupabase(
    String userId,
    Map<String, dynamic> userData,
  );

  // Dual storage methods
  Future<void> createUserCardDual(UserCard userCard);
  Future<void> updateUserCardDual(UserCard userCard);
  Future<void> createUserDataDual(String userId, Map<String, dynamic> userData);
  Future<void> updateUserDataDual(String userId, Map<String, dynamic> userData);

  // Selective dual storage (smart field filtering)
  Future<void> updateUserDataSelective(
    String userId,
    Map<String, dynamic> userData,
  );

  // Account deletion methods
  Future<void> deleteUserDataDual(String userId);
}
