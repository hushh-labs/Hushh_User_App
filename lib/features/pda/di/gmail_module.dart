import 'package:get_it/get_it.dart';
import '../../../core/services/supabase_service.dart';
import '../data/data_sources/supabase_gmail_datasource.dart';
import '../data/repository_impl/gmail_repository_impl.dart';
import '../domain/repositories/gmail_repository.dart';
import '../domain/usecases/connect_gmail_usecase.dart';
import '../domain/usecases/sync_gmail_usecase.dart';
import '../domain/usecases/get_gmail_emails_usecase.dart';

class GmailModule {
  static void register() {
    final getIt = GetIt.instance;

    // Data Sources
    getIt.registerLazySingleton<SupabaseGmailDataSource>(
      () => SupabaseGmailDataSourceImpl(getIt<SupabaseService>()),
    );

    // Repositories
    getIt.registerLazySingleton<GmailRepository>(
      () => GmailRepositoryImpl(getIt<SupabaseGmailDataSource>()),
    );

    // Use Cases
    getIt.registerFactory<ConnectGmailUseCase>(
      () => ConnectGmailUseCase(getIt<GmailRepository>()),
    );

    getIt.registerFactory<SyncGmailUseCase>(
      () => SyncGmailUseCase(getIt<GmailRepository>()),
    );

    getIt.registerFactory<GetGmailEmailsUseCase>(
      () => GetGmailEmailsUseCase(getIt<GmailRepository>()),
    );
  }

  static void unregister() {
    final getIt = GetIt.instance;

    // Unregister in reverse order
    getIt.unregister<GetGmailEmailsUseCase>();
    getIt.unregister<SyncGmailUseCase>();
    getIt.unregister<ConnectGmailUseCase>();
    getIt.unregister<GmailRepository>();
    getIt.unregister<SupabaseGmailDataSource>();
  }
}
