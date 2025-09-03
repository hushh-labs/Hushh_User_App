import 'package:get_it/get_it.dart';
import '../data/datasources/profile_remote_datasource.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/usecases/get_profile_usecase.dart';
import '../domain/usecases/update_profile_usecase.dart';
import '../domain/usecases/upload_profile_image_usecase.dart';
import '../presentation/bloc/profile_bloc.dart';
import '../../auth/domain/repositories/auth_repository.dart';

final getIt = GetIt.instance;

class ProfileModule {
  static void init() {
    // Data sources
    getIt.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(getIt<AuthRepository>()),
    );

    // Repository
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt()),
    );

    // Use cases
    getIt.registerLazySingleton(() => GetProfileUseCase(getIt()));
    getIt.registerLazySingleton(() => UpdateProfileUseCase(getIt()));
    getIt.registerLazySingleton(() => UploadProfileImageUseCase(getIt()));

    // BLoC
    getIt.registerFactory(
      () => ProfileBloc(
        getProfileUseCase: getIt(),
        updateProfileUseCase: getIt(),
        uploadProfileImageUseCase: getIt(),
      ),
    );
  }
}
