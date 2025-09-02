import 'package:get_it/get_it.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/pda_data_source.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/pda_vertex_ai_data_source_impl.dart';
import 'package:hushh_user_app/features/pda/data/repository_impl/pda_repository_impl.dart';
import 'package:hushh_user_app/features/pda/domain/repository/pda_repository.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/clear_messages_use_case.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/get_messages_use_case.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/search_relevant_messages_detailed_use_case.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/search_relevant_messages_use_case.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/send_message_use_case.dart';

class PdaModule {
  static void register() {
    final getIt = GetIt.instance;

    // Data Sources
    getIt.registerLazySingleton<PdaDataSource>(
      () => PdaVertexAiDataSourceImpl(),
    );

    // Repository
    getIt.registerLazySingleton<PdaRepository>(
      () => PdaRepositoryImpl(getIt<PdaDataSource>()),
    );

    // Use Cases
    getIt.registerLazySingleton(
      () => GetMessagesUseCase(getIt<PdaRepository>()),
    );
    getIt.registerLazySingleton(
      () => PdaSendMessageUseCase(getIt<PdaRepository>()),
    );
    getIt.registerLazySingleton(
      () => ClearMessagesUseCase(getIt<PdaRepository>()),
    );
    getIt.registerLazySingleton(
      () => SearchRelevantMessagesUseCase(getIt<PdaRepository>()),
    );
    getIt.registerLazySingleton(
      () => SearchRelevantMessagesDetailedUseCase(getIt<PdaRepository>()),
    );
  }
}
