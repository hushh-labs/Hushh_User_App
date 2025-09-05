import 'package:get_it/get_it.dart';
import '../domain/repositories/simple_linkedin_repository.dart';
import '../domain/repositories/linkedin_repository.dart';
import '../data/repository_impl/simple_linkedin_repository_impl.dart';
import '../data/repository_impl/linkedin_repository_impl.dart';
import '../data/services/supabase_linkedin_service.dart' as full;
import '../../../core/services/supabase_service.dart';

class LinkedInModule {
  static bool _isRegistered = false;

  static void register() {
    if (_isRegistered) return;

    final getIt = GetIt.instance;

    // Repositories
    getIt.registerLazySingleton<SimpleLinkedInRepository>(
      () => SimpleLinkedInRepositoryImpl(getIt<SupabaseService>()),
    );

    getIt.registerLazySingleton<LinkedInRepository>(
      () => LinkedInRepositoryImpl(getIt<SupabaseService>()),
    );

    // Services
    getIt.registerLazySingleton<full.SupabaseLinkedInService>(
      () => full.SupabaseLinkedInService(),
    );

    _isRegistered = true;
  }
}
