import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_card.dart';
import '../models/user_card_model.dart';
import '../../../../shared/constants/firestore_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Store verification ID for OTP verification
  String? _verificationId;

  @override
  Future<void> sendPhoneOtp(
    String phoneNumber, {
    Function(String phoneNumber)? onOtpSent,
  }) async {
    try {
      // Ensure phone number has proper format
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        formattedPhone = '+$phoneNumber';
      }

      // Use a Completer to handle the async callback properly
      final completer = Completer<void>();

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted:
            (firebase_auth.PhoneAuthCredential credential) async {
              // Completely disable auto-verification to force manual OTP entry
              // Do nothing - let user manually enter OTP
            },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          // Handle specific Firebase error codes
          String errorMessage;
          switch (e.code) {
            case 'too-many-requests':
              errorMessage =
                  'Too many OTP requests. Please wait a few minutes before trying again.';
              break;
            case 'invalid-phone-number':
              errorMessage =
                  'Invalid phone number format. Please check and try again.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later.';
              break;
            case 'network-request-failed':
              errorMessage =
                  'Network error. Please check your internet connection and try again.';
              break;
            default:
              errorMessage = 'Failed to send OTP: ${e.message}';
          }

          // Complete with error
          if (!completer.isCompleted) {
            completer.completeError(Exception(errorMessage));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          // Store verification ID for later use
          _verificationId = verificationId;

          // Complete successfully
          if (!completer.isCompleted) {
            completer.complete();
          }

          // Call navigation callback if provided
          if (onOtpSent != null) {
            onOtpSent(phoneNumber);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // OTP auto-retrieval timeout
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        timeout: const Duration(seconds: 60),
      );

      // Wait for the completer to complete
      await completer.future;
    } catch (e) {
      // Re-throw the exception with the specific error message
      if (e is Exception) {
        throw e;
      } else {
        throw Exception('Failed to send OTP: $e');
      }
    }
  }

  @override
  Future<firebase_auth.UserCredential> verifyPhoneOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      if (_verificationId == null) {
        throw Exception('No verification ID found. Please send OTP first.');
      }

      // Create credential with verification ID and OTP
      firebase_auth.PhoneAuthCredential credential =
          firebase_auth.PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: otp,
          );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Clear verification ID after successful verification
      _verificationId = null;

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    try {
      // For email OTP, you might use a custom solution or Firebase Auth
      // This is a placeholder - implement based on your email OTP service
      throw UnimplementedError('Email OTP not implemented yet');
    } catch (e) {
      throw Exception('Failed to send email OTP: $e');
    }
  }

  @override
  Future<firebase_auth.UserCredential> verifyEmailOtp(
    String email,
    String otp,
  ) async {
    try {
      // Placeholder implementation
      throw UnimplementedError('Email OTP verification not implemented yet');
    } catch (e) {
      throw Exception('Failed to verify email OTP: $e');
    }
  }

  @override
  Future<firebase_auth.User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCard?> getUserCard(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return UserCardModel.fromJson({'id': doc.id, ...data});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user card: $e');
    }
  }

  @override
  Future<void> createUserCard(UserCard userCard) async {
    try {
      final now = DateTime.now();
      final cardData = userCard.toJson()
        ..['createdAt'] = now.toIso8601String()
        ..['updatedAt'] = now.toIso8601String();

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userCard.userId)
          .set(cardData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create user card: $e');
    }
  }

  @override
  Future<void> updateUserCard(UserCard userCard) async {
    try {
      final now = DateTime.now();
      final cardData = userCard.toJson()..['updatedAt'] = now.toIso8601String();

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userCard.userId)
          .update(cardData);
    } catch (e) {
      throw Exception('Failed to update user card: $e');
    }
  }

  @override
  Future<bool> doesUserCardExist(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user card existence: $e');
    }
  }

  @override
  Future<void> createUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final now = DateTime.now();
      final data = {
        ...userData,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .set(data);
    } catch (e) {
      throw Exception('Failed to create user data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
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
      final now = DateTime.now();
      final data = {...userData, 'updatedAt': now.toIso8601String()};

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }
}
