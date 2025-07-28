import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  const ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<ProfileEntity> getProfile() async {
    try {
      final profileModel = await remoteDataSource.getProfile();
      return profileModel; // ProfileModel extends ProfileEntity
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  @override
  Future<ProfileEntity> updateProfile({String? name, String? avatar}) async {
    try {
      final profileModel = await remoteDataSource.updateProfile(
        name: name,
        avatar: avatar,
      );
      return profileModel; // ProfileModel extends ProfileEntity
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String imagePath) async {
    try {
      return await remoteDataSource.uploadProfileImage(imagePath);
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  @override
  Future<void> deleteProfileImage() async {
    try {
      await remoteDataSource.deleteProfileImage();
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }
}
