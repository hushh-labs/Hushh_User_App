import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:hushh_user_app/shared/domain/usecases/base_usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneOtpParams {
  final String phoneNumber;
  final String otp;

  VerifyPhoneOtpParams({required this.phoneNumber, required this.otp});
}

class VerifyPhoneOtpUseCase
    implements BaseUseCase<firebase_auth.UserCredential, VerifyPhoneOtpParams> {
  final AuthRepository _authRepository;

  VerifyPhoneOtpUseCase(this._authRepository);

  @override
  Future<Either<Failure, firebase_auth.UserCredential>> call(
    VerifyPhoneOtpParams params,
  ) async {
    try {
      final result = await _authRepository.verifyPhoneOtp(
        params.phoneNumber,
        params.otp,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
