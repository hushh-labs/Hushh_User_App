import 'package:get_it/get_it.dart';

import '../domain/repositories/google_meet_repository.dart';
import '../data/repository_impl/google_meet_repository_impl.dart';
import '../data/data_sources/google_meet_supabase_data_source.dart';
import '../data/data_sources/google_meet_supabase_data_source_impl.dart';
import '../data/services/google_meet_context_prewarm_service.dart';
import '../data/services/google_meet_cache_manager.dart';
import '../data/services/google_calendar_context_prewarm_service.dart';

class GoogleMeetModule {
  static void register() {
    final getIt = GetIt.instance;

    // Data Sources
    getIt.registerLazySingleton<GoogleMeetSupabaseDataSource>(
      () => GoogleMeetSupabaseDataSourceImpl(),
    );

    // Repository
    getIt.registerLazySingleton<GoogleMeetRepository>(
      () => GoogleMeetRepositoryImpl(
        supabaseDataSource: getIt<GoogleMeetSupabaseDataSource>(),
        calendarContextPrewarmService:
            getIt<GoogleCalendarContextPrewarmService>(),
      ),
    );

    // Services
    getIt.registerLazySingleton<GoogleMeetCacheManager>(
      () => GoogleMeetCacheManager(),
    );

    getIt.registerLazySingleton<GoogleMeetContextPrewarmService>(
      () => GoogleMeetContextPrewarmService(),
    );
  }

  static void unregister() {
    final getIt = GetIt.instance;

    // Unregister in reverse order
    if (getIt.isRegistered<GoogleMeetContextPrewarmService>()) {
      getIt.unregister<GoogleMeetContextPrewarmService>();
    }

    if (getIt.isRegistered<GoogleMeetCacheManager>()) {
      getIt.unregister<GoogleMeetCacheManager>();
    }

    if (getIt.isRegistered<GoogleMeetRepository>()) {
      getIt.unregister<GoogleMeetRepository>();
    }

    if (getIt.isRegistered<GoogleMeetSupabaseDataSource>()) {
      getIt.unregister<GoogleMeetSupabaseDataSource>();
    }
  }
}
