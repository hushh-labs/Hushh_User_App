import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_card.dart';
import '../models/user_card_model.dart';
import '../datasources/supabase_auth_datasource.dart';
import '../../../../shared/constants/firestore_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseAuthDataSource _supabaseDataSource;

  AuthRepositoryImpl(this._supabaseDataSource);

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
        rethrow;
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

  // Supabase user card management methods
  @override
  Future<void> createUserCardInSupabase(UserCard userCard) async {
    try {
      await _supabaseDataSource.createUserCard(userCard);
    } catch (e) {
      // Log error but don't throw to maintain backward compatibility
      print('Warning: Failed to create user card in Supabase: $e');
    }
  }

  @override
  Future<UserCard?> getUserCardFromSupabase(String userId) async {
    try {
      return await _supabaseDataSource.getUserCard(userId);
    } catch (e) {
      // Log error but don't throw to maintain backward compatibility
      print('Warning: Failed to get user card from Supabase: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserCardInSupabase(UserCard userCard) async {
    try {
      await _supabaseDataSource.updateUserCard(userCard);
    } catch (e) {
      // Log error but don't throw to maintain backward compatibility
      print('Warning: Failed to update user card in Supabase: $e');
    }
  }

  @override
  Future<bool> doesUserCardExistInSupabase(String userId) async {
    try {
      return await _supabaseDataSource.doesUserCardExist(userId);
    } catch (e) {
      // Log error but don't throw to maintain backward compatibility
      print('Warning: Failed to check user card existence in Supabase: $e');
      return false;
    }
  }

  // Supabase user data management methods
  @override
  Future<void> createUserDataInSupabase(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _supabaseDataSource.createUserData(userId, userData);
    } catch (e) {
      // Log error but don't throw to maintain backward compatibility
      print('Warning: Failed to create user data in Supabase: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserDataFromSupabase(String userId) async {
    try {
      return await _supabaseDataSource.getUserData(userId);
    } catch (e) {
      // Log error but don't throw to maintain backward compatibility
      print('Warning: Failed to get user data from Supabase: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserDataInSupabase(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _supabaseDataSource.updateUserData(userId, userData);
    } catch (e) {
      // Log error but don't throw to maintain backward compatibility
      print('Warning: Failed to update user data in Supabase: $e');
    }
  }

  // Dual storage methods
  @override
  Future<void> createUserCardDual(UserCard userCard) async {
    // Always create in Firebase first (primary source of truth)
    await createUserCard(userCard);

    // Then create in Supabase (for future use)
    // This is done asynchronously and won't affect the main flow if it fails
    await createUserCardInSupabase(userCard);
  }

  @override
  Future<void> updateUserCardDual(UserCard userCard) async {
    // Always update in Firebase first (primary source of truth)
    await updateUserCard(userCard);

    // Then update in Supabase (for future use)
    // This is done asynchronously and won't affect the main flow if it fails
    await updateUserCardInSupabase(userCard);
  }

  @override
  Future<void> createUserDataDual(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    // Always create in Firebase first (primary source of truth)
    await createUserData(userId, userData);

    // Then create in Supabase (for future use)
    // This is done asynchronously and won't affect the main flow if it fails
    await createUserDataInSupabase(userId, userData);
  }

  @override
  Future<void> updateUserDataDual(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    // Always update in Firebase first (primary source of truth)
    await updateUserData(userId, userData);

    // Then update in Supabase (for future use)
    // This is done asynchronously and won't affect the main flow if it fails
    await updateUserDataInSupabase(userId, userData);
  }

  @override
  Future<void> updateUserDataSelective(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    print('🔄 [Dual Storage] Starting selective update for user: $userId');
    print('📋 [Input Data] Fields: ${userData.keys.join(', ')}');

    // Always update Firebase with all data (primary source of truth)
    await updateUserData(userId, userData);
    print('✅ [Firebase] Updated with ALL fields');

    // Filter data for Supabase - exclude fields not present in Supabase schema
    final supabaseData = _filterDataForSupabase(userData);

    // Only update Supabase if there's relevant data to update
    if (supabaseData.isNotEmpty) {
      await updateUserDataInSupabase(userId, supabaseData);
      print('✅ [Supabase] Updated with filtered fields');
    } else {
      print('⏭️ [Supabase] Skipped - no valid fields to update');
    }

    print('🎯 [Dual Storage] Selective update completed');
  }

  /// Filters user data to include only fields that exist in Supabase table
  /// Uses an allow-list approach to ensure only valid Supabase fields are included
  Map<String, dynamic> _filterDataForSupabase(Map<String, dynamic> userData) {
    // Fields that actually exist in Supabase hush_users table
    // This matches the exact table schema from create_hush_users_table.sql
    const allowedSupabaseFields = {
      // Primary key
      'userId',

      // User information fields
      'email',
      'fullName',
      'phoneNumber',
      'isActive',

      // Timestamp fields (both camelCase and snake_case versions)
      'createdAt',
      'updatedAt',
      'created_at',
      'updated_at',

      // Additional user verification/status fields that might be added
      // NOTE: 'isPhoneVerified' is NOT in Supabase schema - only stored in Firebase
      'isEmailVerified',
      'platform',

      // Any other user data fields that are not media-related
      'fcm_token',
      'last_token_update',
      'id', // Sometimes included in updates
    };

    final filteredData = <String, dynamic>{};
    final excludedFields = <String>[];

    for (final entry in userData.entries) {
      final key = entry.key;
      final value = entry.value;

      // Include only if it's in the allowed Supabase fields list
      if (allowedSupabaseFields.contains(key)) {
        // Convert camelCase timestamp fields to snake_case for Supabase
        if (key == 'createdAt') {
          filteredData['created_at'] = value;
        } else if (key == 'updatedAt') {
          filteredData['updated_at'] = value;
        } else {
          filteredData[key] = value;
        }
      } else {
        excludedFields.add(key);
      }
    }

    // Log what was filtered out for debugging
    if (excludedFields.isNotEmpty) {
      print(
        '🔍 [Supabase Filter] Excluded fields: ${excludedFields.join(', ')}',
      );
    }
    if (filteredData.isNotEmpty) {
      print(
        '✅ [Supabase Filter] Included fields: ${filteredData.keys.join(', ')}',
      );
    }

    return filteredData;
  }

  @override
  Future<void> deleteUserDataDual(String userId) async {
    print('🗑️ [Dual Storage] Starting account deletion for user: $userId');

    // Always delete from Firebase first (primary source of truth)
    try {
      // Delete PDA messages subcollection if it exists
      await _deletePdaMessagesSubcollection(userId);

      // Delete PDA context from pdaContext collection if it exists
      await _deletePdaContext(userId);

      // Delete main user document
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .delete();
      print('✅ [Firebase] User data and subcollections deleted successfully');
    } catch (e) {
      print('❌ [Firebase] Failed to delete user data: $e');
      throw Exception('Failed to delete user data from Firebase: $e');
    }

    // Try to delete from Supabase, but don't fail if user doesn't exist there
    try {
      // First check if user exists in Supabase
      final userExists = await doesUserCardExistInSupabase(userId);

      if (userExists) {
        await _supabaseDataSource.deleteUserData(userId);
        print('✅ [Supabase] User data deleted successfully');
      } else {
        print('⏭️ [Supabase] User not found - skipping deletion');
      }
    } catch (e) {
      // Log the error but don't throw - Supabase deletion is not critical
      print('⚠️ [Supabase] Failed to delete user data (non-critical): $e');
    }

    print('🎯 [Dual Storage] Account deletion completed');
  }

  /// Deletes PDA messages subcollection for the user
  Future<void> _deletePdaMessagesSubcollection(String userId) async {
    try {
      print('🗑️ [PDA] Deleting PDA messages subcollection for user: $userId');

      // Get all messages in the subcollection
      final messagesQuery = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection('pda_messages')
          .get();

      if (messagesQuery.docs.isEmpty) {
        print('⏭️ [PDA] No PDA messages found - skipping deletion');
        return;
      }

      // Delete messages in batches (Firestore batch limit is 500)
      final batch = _firestore.batch();
      int count = 0;

      for (final doc in messagesQuery.docs) {
        batch.delete(doc.reference);
        count++;

        // Execute batch if we reach 500 operations
        if (count >= 500) {
          await batch.commit();
          count = 0;
        }
      }

      // Execute remaining operations
      if (count > 0) {
        await batch.commit();
      }

      print('✅ [PDA] Deleted ${messagesQuery.docs.length} PDA messages');
    } catch (e) {
      print('⚠️ [PDA] Failed to delete PDA messages (non-critical): $e');
      // Don't throw - this is not critical for account deletion
    }
  }

  /// Deletes PDA context from pdaContext collection
  Future<void> _deletePdaContext(String userId) async {
    try {
      print('🗑️ [PDA] Deleting PDA context for user: $userId');

      // Check if PDA context document exists
      final pdaContextDoc = await _firestore
          .collection('pdaContext')
          .doc(userId)
          .get();

      if (!pdaContextDoc.exists) {
        print('⏭️ [PDA] No PDA context found - skipping deletion');
        return;
      }

      // Delete the PDA context document
      await _firestore.collection('pdaContext').doc(userId).delete();

      print('✅ [PDA] PDA context deleted successfully');
    } catch (e) {
      print('⚠️ [PDA] Failed to delete PDA context (non-critical): $e');
      // Don't throw - this is not critical for account deletion
    }
  }
}
