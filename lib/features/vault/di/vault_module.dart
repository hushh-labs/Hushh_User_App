import 'package:get_it/get_it.dart';
import 'package:hushh_user_app/features/vault/data/data_sources/supabase_storage_datasource.dart';
import 'package:hushh_user_app/features/vault/data/data_sources/supabase_vault_datasource.dart';
import 'package:hushh_user_app/features/vault/data/repository_impl/vault_repository_impl.dart';
import 'package:hushh_user_app/features/vault/data/services/supabase_document_context_prewarm_service.dart';
import 'package:hushh_user_app/features/vault/data/services/document_processing_service.dart';
import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';
import 'package:hushh_user_app/features/vault/domain/usecases/delete_document_usecase.dart';
import 'package:hushh_user_app/features/vault/domain/usecases/get_documents_usecase.dart';
import 'package:hushh_user_app/features/vault/domain/usecases/upload_document_usecase.dart';
import 'package:hushh_user_app/features/vault/presentation/bloc/vault_bloc.dart';

class VaultModule {
  static void init(GetIt sl) {
    // Data sources (register first as they are dependencies)
    sl.registerLazySingleton<SupabaseStorageDataSource>(
      () => SupabaseStorageDataSourceImpl(),
    );
    sl.registerLazySingleton<SupabaseVaultDataSource>(
      () => SupabaseVaultDataSourceImpl(),
    );

    // Services
    sl.registerLazySingleton<DocumentProcessingService>(
      () => DocumentProcessingServiceImpl(),
    );
    sl.registerLazySingleton<SupabaseDocumentContextPrewarmService>(
      () => SupabaseDocumentContextPrewarmServiceImpl(),
    );

    // Repositories
    sl.registerLazySingleton<VaultRepository>(
      () => VaultRepositoryImpl(
        supabaseStorageDataSource: sl(),
        supabaseVaultDataSource: sl(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => UploadDocumentUseCase(sl()));
    sl.registerLazySingleton(() => DeleteDocumentUseCase(sl()));
    sl.registerLazySingleton(() => GetDocumentsUseCase(sl()));

    // Blocs
    sl.registerFactory(
      () => VaultBloc(
        uploadDocumentUseCase: sl(),
        deleteDocumentUseCase: sl(),
        getDocumentsUseCase: sl(),
      ),
    );
  }
}
