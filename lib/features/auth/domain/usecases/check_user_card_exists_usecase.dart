import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:hushh_user_app/shared/domain/usecases/base_usecase.dart';
import '../repositories/auth_repository.dart';

class CheckUserCardExistsUseCase implements BaseUseCase<bool, String> {
  final AuthRepository _authRepository;

  CheckUserCardExistsUseCase(this._authRepository);

  @override
  Future<Either<Failure, bool>> call(String userId) async {
    try {
      final exists = await _authRepository.doesUserCardExist(userId);
      return Right(exists);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
