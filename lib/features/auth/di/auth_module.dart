import 'package:get_it/get_it.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/send_phone_otp_usecase.dart';
import '../domain/usecases/verify_phone_otp_usecase.dart';
import '../domain/usecases/check_user_card_exists_usecase.dart';
import '../domain/usecases/create_user_card_usecase.dart';
import '../domain/usecases/sign_out_usecase.dart';
import '../presentation/bloc/auth_bloc.dart';

class AuthModule {
  static void register() {
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
      () => CheckUserCardExistsUseCase(getIt<AuthRepository>()),
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
        checkUserCardExistsUseCase: getIt<CheckUserCardExistsUseCase>(),
        createUserCardUseCase: getIt<CreateUserCardUseCase>(),
        signOutUseCase: getIt<SignOutUseCase>(),
      ),
    );
  }
}
