import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:hushh_user_app/shared/domain/usecases/base_usecase.dart';
import '../repositories/auth_repository.dart';

class SendPhoneOtpUseCase implements BaseUseCase<void, SendPhoneOtpParams> {
  final AuthRepository _authRepository;

  SendPhoneOtpUseCase(this._authRepository);

  @override
  Future<Either<Failure, void>> call(SendPhoneOtpParams params) async {
    try {
      print('🔥 [USE_CASE] Calling sendPhoneOtp for: ${params.phoneNumber}');
      await _authRepository.sendPhoneOtp(
        params.phoneNumber,
        onOtpSent: params.onOtpSent,
      );
      print('🔥 [USE_CASE] sendPhoneOtp successful');
      return const Right(null);
    } catch (e) {
      print('🔥 [USE_CASE] sendPhoneOtp failed: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}

class SendPhoneOtpParams {
  final String phoneNumber;
  final Function(String phoneNumber)? onOtpSent;

  SendPhoneOtpParams({required this.phoneNumber, this.onOtpSent});
}
