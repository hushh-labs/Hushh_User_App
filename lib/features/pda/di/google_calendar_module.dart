import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/supabase_service.dart';
import '../data/data_sources/google_calendar_api_data_source.dart';
import '../data/data_sources/google_calendar_api_data_source_impl.dart';
import '../data/data_sources/google_calendar_supabase_data_source.dart';
import '../data/data_sources/google_calendar_supabase_data_source_impl.dart';
import '../data/data_sources/google_meet_supabase_data_source.dart';
import '../data/services/google_calendar_cache_manager.dart';
import '../data/services/google_calendar_context_prewarm_service.dart';

class GoogleCalendarModule {
  static void register() {
    final getIt = GetIt.instance;

    // Register Google Calendar API data source
    getIt.registerLazySingleton<GoogleCalendarApiDataSource>(
      () => GoogleCalendarApiDataSourceImpl(httpClient: getIt<http.Client>()),
    );

    // Register Google Calendar Supabase data source
    getIt.registerLazySingleton<GoogleCalendarSupabaseDataSource>(
      () =>
          GoogleCalendarSupabaseDataSourceImpl(getIt<SupabaseService>().client),
    );

    // Register Google Calendar cache manager
    getIt.registerLazySingleton<GoogleCalendarCacheManager>(
      () => GoogleCalendarCacheManager(getIt<SharedPreferences>()),
    );

    // Register Google Calendar context prewarm service
    getIt.registerLazySingleton<GoogleCalendarContextPrewarmService>(
      () => GoogleCalendarContextPrewarmService(
        getIt<GoogleCalendarApiDataSource>(),
        getIt<GoogleCalendarSupabaseDataSource>(),
        getIt<GoogleMeetSupabaseDataSource>(),
        getIt<GoogleCalendarCacheManager>(),
        getIt<SharedPreferences>(),
      ),
    );
  }
}
