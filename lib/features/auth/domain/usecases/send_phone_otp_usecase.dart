import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:hushh_user_app/shared/domain/usecases/base_usecase.dart';
import '../repositories/auth_repository.dart';

class SendPhoneOtpUseCase implements BaseUseCase<void, SendPhoneOtpParams> {
  final AuthRepository _authRepository;

  SendPhoneOtpUseCase(this._authRepository);

  @override
  Future<Either<Failure, void>> call(SendPhoneOtpParams params) async {
    print('📞 [SEND_OTP_USECASE] Starting SendPhoneOtpUseCase');
    print('📱 [SEND_OTP_USECASE] Phone number: ${params.phoneNumber}');
    print(
      '🔄 [SEND_OTP_USECASE] Has onOtpSent callback: ${params.onOtpSent != null}',
    );

    try {
      print('⏳ [SEND_OTP_USECASE] Calling auth repository sendPhoneOtp...');

      await _authRepository.sendPhoneOtp(
        params.phoneNumber,
        onOtpSent: params.onOtpSent,
      );

      print('✅ [SEND_OTP_USECASE] Repository call completed successfully');
      return const Right(null);
    } catch (e) {
      print('💥 [SEND_OTP_USECASE] Exception caught: $e');
      print('📊 [SEND_OTP_USECASE] Exception type: ${e.runtimeType}');
      print('🔄 [SEND_OTP_USECASE] Returning ServerFailure');
      return Left(ServerFailure(e.toString()));
    }
  }
}

class SendPhoneOtpParams {
  final String phoneNumber;
  final Function(String phoneNumber)? onOtpSent;

  SendPhoneOtpParams({required this.phoneNumber, this.onOtpSent});
}
