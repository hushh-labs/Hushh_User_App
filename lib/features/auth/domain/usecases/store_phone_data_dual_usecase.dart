import '../repositories/auth_repository.dart';

class StorePhoneDataDualUseCase {
  final AuthRepository _authRepository;

  StorePhoneDataDualUseCase(this._authRepository);

  Future<void> call(String userId, String phoneNumber) async {
    // Create user data with phone number and verification status
    // The repository will handle filtering fields for each storage system
    final userData = {
      'phoneNumber': phoneNumber,
      'isPhoneVerified': true, // Only goes to Firebase (not in Supabase schema)
    };

    // Use selective dual storage - filters out unsupported fields for Supabase
    await _authRepository.updateUserDataSelective(userId, userData);
  }
}
