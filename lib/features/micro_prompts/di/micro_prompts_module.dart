import 'package:get_it/get_it.dart';
import 'package:hushh_user_app/features/micro_prompts/data/data_sources/micro_prompts_supabase_data_source.dart';
import 'package:hushh_user_app/features/micro_prompts/data/data_sources/micro_prompts_supabase_data_source_impl.dart';
import 'package:hushh_user_app/features/micro_prompts/data/repository_impl/micro_prompts_repository_impl.dart';
import 'package:hushh_user_app/features/micro_prompts/data/services/micro_prompts_scheduler_service.dart';
import 'package:hushh_user_app/features/micro_prompts/domain/repositories/micro_prompts_repository.dart';
import 'package:hushh_user_app/features/micro_prompts/presentation/bloc/micro_prompts_bloc.dart';

class MicroPromptsModule {
  static void init(GetIt sl) {
    // Data sources (register first as they are dependencies)
    sl.registerLazySingleton<MicroPromptsSupabaseDataSource>(
      () => MicroPromptsSupabaseDataSourceImpl(),
    );

    // Services
    sl.registerLazySingleton<MicroPromptsSchedulerService>(
      () => MicroPromptsSchedulerService(sl()),
    );

    // Repositories
    sl.registerLazySingleton<MicroPromptsRepository>(
      () => MicroPromptsRepositoryImpl(sl()),
    );

    // Blocs
    sl.registerFactory(() => MicroPromptsBloc(sl()));
  }
}
