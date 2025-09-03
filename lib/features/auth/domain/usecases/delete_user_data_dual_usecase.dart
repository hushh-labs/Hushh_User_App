import '../repositories/auth_repository.dart';

class DeleteUserDataDualUseCase {
  final AuthRepository repository;

  DeleteUserDataDualUseCase(this.repository);

  /// Deletes user data from both Firebase and Supabase
  /// Firebase deletion will always be attempted first (primary source)
  /// Supabase deletion is attempted but won't fail the operation if user doesn't exist there
  ///
  /// This ensures proper cleanup across both storage systems
  Future<void> call(String userId) async {
    await repository.deleteUserDataDual(userId);
  }
}
