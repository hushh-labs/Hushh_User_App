import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/profile_model.dart';
import '../../../../shared/constants/firestore_constants.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile({String? name, String? avatar});
  Future<String> uploadProfileImage(String imagePath);
  Future<void> deleteProfileImage();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthRepository _authRepository;

  ProfileRemoteDataSourceImpl(this._authRepository);

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Create a default profile if it doesn't exist
        final defaultProfile = {
          'id': user.uid,
          'fullName': user.displayName ?? 'User',
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'avatar': user.photoURL,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isEmailVerified': user.emailVerified,
          'isPhoneVerified':
              user.phoneNumber != null, // Set to true if phone number exists
        };

        // Save the default profile using dual storage
        await _authRepository.createUserDataDual(user.uid, defaultProfile);

        return ProfileModel.fromJson(defaultProfile);
      }

      final data = doc.data()!;
      final profileData = {'id': doc.id, ...data};

      // Update phone number if it's missing but user has one
      if (profileData['phoneNumber'] == null && user.phoneNumber != null) {
        final phoneUpdateData = {
          'phoneNumber': user.phoneNumber,
          'isPhoneVerified': true,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Update both Firebase and Supabase (phone data is relevant for both)
        await _authRepository.updateUserDataDual(user.uid, phoneUpdateData);

        // Update the profile data with the phone number
        profileData['phoneNumber'] = user.phoneNumber;
        profileData['isPhoneVerified'] = true;
      }

      return ProfileModel.fromJson(profileData);
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  @override
  Future<ProfileModel> updateProfile({String? name, String? avatar}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) {
        updateData['fullName'] = name;
      }
      if (avatar != null) {
        updateData['avatar'] = avatar;
      }

      // Use selective dual storage - automatically filters out avatar/video fields for Supabase
      await _authRepository.updateUserDataSelective(user.uid, updateData);

      return await getProfile();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String imagePath) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final file = File(imagePath);
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  @override
  Future<void> deleteProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current profile to find the image URL
      final profile = await getProfile();
      if (profile.avatar != null) {
        // Extract the path from the URL and delete from storage
        final ref = _storage.refFromURL(profile.avatar!);
        await ref.delete();
      }

      // Update profile to remove avatar
      await updateProfile(avatar: null);
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }
}
