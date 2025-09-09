import 'package:get_it/get_it.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/calendar_supabase_data_source.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/calendar_supabase_data_source_impl.dart';
import 'package:hushh_user_app/features/pda/data/repository_impl/calendar_repository_impl.dart';
import 'package:hushh_user_app/features/pda/domain/repositories/calendar_repository.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/calendar_use_cases.dart';

class CalendarModule {
  static void register() {
    final getIt = GetIt.instance;

    // Data Sources
    getIt.registerLazySingleton<CalendarSupabaseDataSource>(
      () => CalendarSupabaseDataSourceImpl(),
    );

    // Repository
    getIt.registerLazySingleton<CalendarRepository>(
      () => CalendarRepositoryImpl(
        dataSource: getIt<CalendarSupabaseDataSource>(),
      ),
    );

    // Use Cases
    getIt.registerLazySingleton<GetCalendarEventsUseCase>(
      () => GetCalendarEventsUseCase(getIt<CalendarRepository>()),
    );
    getIt.registerLazySingleton<GetUpcomingEventsUseCase>(
      () => GetUpcomingEventsUseCase(getIt<CalendarRepository>()),
    );
    getIt.registerLazySingleton<GetEventsInRangeUseCase>(
      () => GetEventsInRangeUseCase(getIt<CalendarRepository>()),
    );
    getIt.registerLazySingleton<GetTodayEventsUseCase>(
      () => GetTodayEventsUseCase(getIt<CalendarRepository>()),
    );
    getIt.registerLazySingleton<GetEventsForDateUseCase>(
      () => GetEventsForDateUseCase(getIt<CalendarRepository>()),
    );
    getIt.registerLazySingleton<IsCalendarConnectedUseCase>(
      () => IsCalendarConnectedUseCase(getIt<CalendarRepository>()),
    );
    getIt.registerLazySingleton<RefreshCalendarDataUseCase>(
      () => RefreshCalendarDataUseCase(getIt<CalendarRepository>()),
    );
  }

  static void unregister() {
    final getIt = GetIt.instance;

    if (getIt.isRegistered<RefreshCalendarDataUseCase>()) {
      getIt.unregister<RefreshCalendarDataUseCase>();
    }
    if (getIt.isRegistered<IsCalendarConnectedUseCase>()) {
      getIt.unregister<IsCalendarConnectedUseCase>();
    }
    if (getIt.isRegistered<GetEventsForDateUseCase>()) {
      getIt.unregister<GetEventsForDateUseCase>();
    }
    if (getIt.isRegistered<GetTodayEventsUseCase>()) {
      getIt.unregister<GetTodayEventsUseCase>();
    }
    if (getIt.isRegistered<GetEventsInRangeUseCase>()) {
      getIt.unregister<GetEventsInRangeUseCase>();
    }
    if (getIt.isRegistered<GetUpcomingEventsUseCase>()) {
      getIt.unregister<GetUpcomingEventsUseCase>();
    }
    if (getIt.isRegistered<GetCalendarEventsUseCase>()) {
      getIt.unregister<GetCalendarEventsUseCase>();
    }
    if (getIt.isRegistered<CalendarRepository>()) {
      getIt.unregister<CalendarRepository>();
    }
    if (getIt.isRegistered<CalendarSupabaseDataSource>()) {
      getIt.unregister<CalendarSupabaseDataSource>();
    }
  }
}
