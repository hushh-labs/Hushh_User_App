import '../../domain/entities/agent_product_revamp.dart';
import '../../domain/entities/lookbook_revamp.dart';
import '../../domain/repositories/agent_profile_repository.dart';
import '../datasources/agent_profile_local_data_source.dart';

class AgentProfileRepositoryImpl implements AgentProfileRepository {
  final AgentProfileLocalDataSource local;

  AgentProfileRepositoryImpl(this.local);

  @override
  Future<List<AgentProductRevamp>> getProducts(String agentId) {
    return local.getProducts(agentId);
  }

  @override
  Future<List<LookbookRevamp>> getLookbooks(String agentId) {
    return local.getLookbooks(agentId);
  }
}
