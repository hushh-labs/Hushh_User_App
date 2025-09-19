import 'package:get_it/get_it.dart';

import '../domain/repositories/discover_revamp_repository.dart';
import '../domain/usecases/get_discover_revamp_items.dart';
import '../data/repositories/discover_revamp_repository_impl.dart';
import '../data/datasources/discover_revamp_remote_data_source.dart';

class DiscoverRevampModule {
  static void init(GetIt getIt) {
    // Data sources
    getIt.registerLazySingleton<DiscoverRevampRemoteDataSource>(
      () => DiscoverRevampRemoteDataSourceImpl(),
    );

    // Repository
    getIt.registerLazySingleton<DiscoverRevampRepository>(
      () =>
          DiscoverRevampRepositoryImpl(getIt<DiscoverRevampRemoteDataSource>()),
    );

    // Use cases
    getIt.registerFactory(
      () => GetDiscoverRevampItems(getIt<DiscoverRevampRepository>()),
    );
  }
}
