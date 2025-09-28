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
    print('🔐 [VERIFY_OTP_USECASE] Starting VerifyPhoneOtpUseCase');
    print('📱 [VERIFY_OTP_USECASE] Phone number: ${params.phoneNumber}');
    print('🔑 [VERIFY_OTP_USECASE] OTP code: ${params.otp}');

    try {
      print('⏳ [VERIFY_OTP_USECASE] Calling auth repository verifyPhoneOtp...');

      final result = await _authRepository.verifyPhoneOtp(
        params.phoneNumber,
        params.otp,
      );

      print('✅ [VERIFY_OTP_USECASE] Repository call completed successfully');
      print('👤 [VERIFY_OTP_USECASE] User ID: ${result.user?.uid}');
      return Right(result);
    } catch (e) {
      print('💥 [VERIFY_OTP_USECASE] Exception caught: $e');
      print('📊 [VERIFY_OTP_USECASE] Exception type: ${e.runtimeType}');
      print('🔄 [VERIFY_OTP_USECASE] Returning ServerFailure');
      return Left(ServerFailure(e.toString()));
    }
  }
}
