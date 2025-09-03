import '../entities/user_card.dart';
import '../repositories/auth_repository.dart';

class CreateUserCardDualUseCase {
  final AuthRepository repository;

  CreateUserCardDualUseCase(this.repository);

  /// Creates user card in both Firebase and Supabase for dual storage
  /// This ensures data redundancy and future migration capabilities
  ///
  /// Firebase remains the primary source of truth for backward compatibility
  /// Supabase storage is for future use and additional functionality
  Future<void> call(UserCard userCard) async {
    await repository.createUserCardDual(userCard);
  }
}
