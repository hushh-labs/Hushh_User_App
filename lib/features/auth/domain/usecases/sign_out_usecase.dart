import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:hushh_user_app/shared/domain/usecases/base_usecase.dart';
import '../repositories/auth_repository.dart';
import 'package:hushh_user_app/core/usecases/usecase.dart';

class SignOutUseCase implements NoParamUseCase<void> {
  final AuthRepository _authRepository;

  SignOutUseCase(this._authRepository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _authRepository.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
