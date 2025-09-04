import 'package:get_it/get_it.dart';
import '../domain/repositories/simple_linkedin_repository.dart';
import '../data/repository_impl/simple_linkedin_repository_impl.dart';
import '../data/services/simple_linkedin_service.dart';
import '../../../core/services/supabase_service.dart';

class LinkedInModule {
  static bool _isRegistered = false;

  static void register() {
    if (_isRegistered) return;

    final getIt = GetIt.instance;

    // Repository
    getIt.registerLazySingleton<SimpleLinkedInRepository>(
      () => SimpleLinkedInRepositoryImpl(getIt<SupabaseService>()),
    );

    // Service
    getIt.registerLazySingleton<SupabaseLinkedInService>(
      () => SupabaseLinkedInService(),
    );

    _isRegistered = true;
  }
}
