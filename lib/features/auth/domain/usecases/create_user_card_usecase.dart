import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:hushh_user_app/shared/domain/usecases/base_usecase.dart';
import '../repositories/auth_repository.dart';
import '../entities/user_card.dart';

class CreateUserCardUseCase implements BaseUseCase<void, UserCard> {
  final AuthRepository _authRepository;

  CreateUserCardUseCase(this._authRepository);

  @override
  Future<Either<Failure, void>> call(UserCard userCard) async {
    try {
      await _authRepository.createUserCard(userCard);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
