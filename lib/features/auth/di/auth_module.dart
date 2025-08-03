import 'package:get_it/get_it.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/send_phone_otp_usecase.dart';
import '../domain/usecases/verify_phone_otp_usecase.dart';
import '../domain/usecases/create_user_card_usecase.dart';
import '../domain/usecases/sign_out_usecase.dart';
import '../presentation/bloc/auth_bloc.dart';
import '../../notifications/data/services/fcm_service.dart';

class AuthModule {
  static bool _isRegistered = false;

  static void register() {
    if (_isRegistered) return;

    final getIt = GetIt.instance;

    // Repository
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

    // Use cases
    getIt.registerLazySingleton(
      () => SendPhoneOtpUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => VerifyPhoneOtpUseCase(getIt<AuthRepository>()),
    );

    getIt.registerLazySingleton(
      () => CreateUserCardUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(() => SignOutUseCase(getIt<AuthRepository>()));

    // BLoC
    getIt.registerFactory(
      () => AuthBloc(
        sendPhoneOtpUseCase: getIt<SendPhoneOtpUseCase>(),
        verifyPhoneOtpUseCase: getIt<VerifyPhoneOtpUseCase>(),
        createUserCardUseCase: getIt<CreateUserCardUseCase>(),
        signOutUseCase: getIt<SignOutUseCase>(),
        fcmService: getIt<FCMService>(),
      ),
    );

    _isRegistered = true;
  }
}
