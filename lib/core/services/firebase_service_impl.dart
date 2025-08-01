// Firebase service implementation
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_constants.dart';
import 'firebase_service.dart';

class FirebaseServiceImpl implements FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Check if user needs to re-authenticate before deletion
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception(
            'Recent authentication required. Please sign in again before deleting your account.',
          );
        }
        throw _handleAuthException(e);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  @override
  Future<bool> needsReauthentication() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Try to get a fresh token - this will fail if re-authentication is needed
      await user.getIdToken(true);
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> reauthenticateUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // For phone-based authentication, we need to re-authenticate
      // This will trigger the phone verification flow again
      // The user will need to go through the phone verification process
      throw Exception(
        'Re-authentication required. Please sign out and sign in again.',
      );
    } catch (e) {
      throw Exception('Failed to re-authenticate user: $e');
    }
  }

  @override
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> addUserData(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .set(userData);
    } catch (e) {
      throw Exception('Failed to add user data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  @override
  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update(userData);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  @override
  Future<void> deleteUserData(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception(FirebaseConstants.userNotFound);
      case 'wrong-password':
        return Exception(FirebaseConstants.wrongPassword);
      case 'email-already-in-use':
        return Exception(FirebaseConstants.emailAlreadyInUse);
      case 'weak-password':
        return Exception(FirebaseConstants.weakPassword);
      case 'invalid-email':
        return Exception(FirebaseConstants.invalidEmail);
      case 'network-request-failed':
        return Exception(FirebaseConstants.networkError);
      default:
        return Exception(FirebaseConstants.defaultErrorMessage);
    }
  }
}
