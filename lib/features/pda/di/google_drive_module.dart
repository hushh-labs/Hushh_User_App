import 'package:get_it/get_it.dart';
import '../domain/repositories/google_drive_repository.dart';
import '../data/repository_impl/google_drive_repository_impl.dart';
import '../data/data_sources/google_drive_supabase_data_source.dart';
import '../data/data_sources/google_drive_supabase_data_source_impl.dart';

class GoogleDriveModule {
  static void register() {
    final getIt = GetIt.instance;

    getIt.registerLazySingleton<GoogleDriveSupabaseDataSource>(
      () => GoogleDriveSupabaseDataSourceImpl(),
    );

    getIt.registerLazySingleton<GoogleDriveRepository>(
      () => GoogleDriveRepositoryImpl(
        dataSource: getIt<GoogleDriveSupabaseDataSource>(),
      ),
    );
  }

  static void unregister() {
    final getIt = GetIt.instance;

    if (getIt.isRegistered<GoogleDriveRepository>()) {
      getIt.unregister<GoogleDriveRepository>();
    }
    if (getIt.isRegistered<GoogleDriveSupabaseDataSource>()) {
      getIt.unregister<GoogleDriveSupabaseDataSource>();
    }
  }
}
