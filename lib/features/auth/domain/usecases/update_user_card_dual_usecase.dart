import '../entities/user_card.dart';
import '../repositories/auth_repository.dart';

class UpdateUserCardDualUseCase {
  final AuthRepository repository;

  UpdateUserCardDualUseCase(this.repository);

  /// Updates user card in both Firebase and Supabase for dual storage
  /// This ensures data consistency across both platforms
  ///
  /// Firebase remains the primary source of truth for backward compatibility
  /// Supabase storage is kept in sync for future use
  Future<void> call(UserCard userCard) async {
    await repository.updateUserCardDual(userCard);
  }
}
