import 'package:get_it/get_it.dart';
import '../data/data_sources/checkout_firebase_data_source.dart';
import '../data/repository_impl/checkout_repository_impl.dart';
import '../domain/repositories/checkout_repository.dart';
import '../domain/usecases/get_checkout_data.dart';
import '../domain/usecases/save_checkout_data.dart';
import '../domain/usecases/get_user_basic_info.dart';
import '../presentation/bloc/checkout_bloc.dart';

class CheckoutModule {
  static void registerDependencies() {
    final getIt = GetIt.instance;

    // Data Sources
    getIt.registerLazySingleton<CheckoutFirebaseDataSource>(
      () => CheckoutFirebaseDataSourceImpl(),
    );

    // Repositories
    getIt.registerLazySingleton<CheckoutRepository>(
      () => CheckoutRepositoryImpl(getIt<CheckoutFirebaseDataSource>()),
    );

    // Use Cases
    getIt.registerLazySingleton<GetCheckoutData>(
      () => GetCheckoutData(getIt<CheckoutRepository>()),
    );
    getIt.registerLazySingleton<SaveCheckoutData>(
      () => SaveCheckoutData(getIt<CheckoutRepository>()),
    );
    getIt.registerLazySingleton<GetUserBasicInfo>(
      () => GetUserBasicInfo(getIt<CheckoutRepository>()),
    );

    // BLoC
    getIt.registerFactory<CheckoutBloc>(
      () => CheckoutBloc(
        getCheckoutData: getIt<GetCheckoutData>(),
        saveCheckoutData: getIt<SaveCheckoutData>(),
        getUserBasicInfo: getIt<GetUserBasicInfo>(),
      ),
    );
  }
}
