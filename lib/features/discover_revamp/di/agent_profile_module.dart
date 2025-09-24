import 'package:get_it/get_it.dart';
import '../data/datasources/agent_profile_local_data_source.dart';
import '../data/datasources/agent_profile_firestore_data_source.dart';
import '../data/repositories/agent_profile_repository_impl.dart';
import '../domain/repositories/agent_profile_repository.dart';
import '../domain/usecases/get_agent_profile_content.dart';

class AgentProfileModule {
  static void register(GetIt getIt) {
    getIt.registerLazySingleton<AgentProfileLocalDataSource>(
      () => AgentProfileFirestoreDataSource(),
    );
    getIt.registerLazySingleton<AgentProfileRepository>(
      () => AgentProfileRepositoryImpl(getIt()),
    );
    getIt.registerFactory<GetAgentProfileContent>(
      () => GetAgentProfileContent(getIt()),
    );
  }
}
