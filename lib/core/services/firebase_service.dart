// Firebase service abstract class
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseService {
  // Auth methods
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  );
  Future<void> signOut();
  Future<void> deleteUser();
  Future<bool> needsReauthentication();
  Future<void> reauthenticateUser();
  User? getCurrentUser();
  Stream<User?> get authStateChanges;

  // Firestore methods
  Future<void> addUserData(String userId, Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData(String userId);
  Future<void> updateUserData(String userId, Map<String, dynamic> userData);
  Future<void> deleteUserData(String userId);
}
