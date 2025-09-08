// Core module for dependency injection
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/network_info.dart';
import '../core/network/network_info_impl.dart';
import '../core/services/firebase_service.dart';
import '../core/services/firebase_service_impl.dart';
import '../core/services/supabase_service.dart';
import '../core/routing/navigation_service.dart';
import '../core/routing/navigation_service_impl.dart';
import '../core/routing/app_router.dart';
import '../features/notifications/di/notification_module.dart';

class CoreModule {
  static void register() {
    final sl = GetIt.instance;

    // Core dependencies
    sl.registerLazySingleton<http.Client>(() => http.Client());

    // SharedPreferences - async registration
    sl.registerSingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance(),
    );

    // Network
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

    // Firebase Service
    sl.registerLazySingleton<FirebaseService>(() => FirebaseServiceImpl());

    // Supabase Service
    sl.registerLazySingleton<SupabaseService>(() => SupabaseService());

    // Navigation Service
    sl.registerLazySingleton<NavigationService>(
      () => NavigationServiceImpl(AppRouter.router),
    );

    // Register feature modules
    NotificationModule.register();
  }
}
