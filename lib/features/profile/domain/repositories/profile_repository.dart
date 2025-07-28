import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  /// Get the current user's profile
  Future<ProfileEntity> getProfile();

  /// Update the user's profile (only name and avatar are editable)
  Future<ProfileEntity> updateProfile({String? name, String? avatar});

  /// Upload profile image and get the URL
  Future<String> uploadProfileImage(String imagePath);

  /// Delete profile image
  Future<void> deleteProfileImage();
}
