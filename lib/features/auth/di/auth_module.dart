import 'package:get_it/get_it.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/datasources/supabase_auth_datasource.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/send_phone_otp_usecase.dart';
import '../domain/usecases/verify_phone_otp_usecase.dart';
import '../domain/usecases/create_user_card_usecase.dart';
import '../domain/usecases/create_user_card_dual_usecase.dart';
import '../domain/usecases/update_user_card_dual_usecase.dart';
import '../domain/usecases/delete_user_data_dual_usecase.dart';
import '../domain/usecases/store_phone_data_dual_usecase.dart';
import '../domain/usecases/sign_out_usecase.dart';
import '../presentation/bloc/auth_bloc.dart';
import '../../../core/services/supabase_service.dart';
import '../../notifications/data/services/fcm_service.dart';

class AuthModule {
  static bool _isRegistered = false;

  static void register() {
    if (_isRegistered) return;

    final getIt = GetIt.instance;

    // Data sources
    getIt.registerLazySingleton<SupabaseAuthDataSource>(
      () => SupabaseAuthDataSourceImpl(getIt<SupabaseService>()),
    );

    // Repository
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<SupabaseAuthDataSource>()),
    );

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
    getIt.registerLazySingleton(
      () => CreateUserCardDualUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => UpdateUserCardDualUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => DeleteUserDataDualUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => StorePhoneDataDualUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(() => SignOutUseCase(getIt<AuthRepository>()));

    // BLoC
    getIt.registerFactory(
      () => AuthBloc(
        sendPhoneOtpUseCase: getIt<SendPhoneOtpUseCase>(),
        verifyPhoneOtpUseCase: getIt<VerifyPhoneOtpUseCase>(),
        createUserCardUseCase: getIt<CreateUserCardUseCase>(),
        createUserCardDualUseCase: getIt<CreateUserCardDualUseCase>(),
        updateUserCardDualUseCase: getIt<UpdateUserCardDualUseCase>(),
        storePhoneDataDualUseCase: getIt<StorePhoneDataDualUseCase>(),
        signOutUseCase: getIt<SignOutUseCase>(),
        fcmService: getIt<FCMService>(),
      ),
    );

    _isRegistered = true;
  }
}
