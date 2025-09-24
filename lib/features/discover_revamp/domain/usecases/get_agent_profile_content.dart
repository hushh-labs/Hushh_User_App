import '../entities/agent_product_revamp.dart';
import '../entities/lookbook_revamp.dart';
import '../repositories/agent_profile_repository.dart';

class GetAgentProfileContent {
  final AgentProfileRepository repository;

  const GetAgentProfileContent(this.repository);

  Future<(List<AgentProductRevamp>, List<LookbookRevamp>)> call(
    String agentId,
  ) async {
    final products = await repository.getProducts(agentId);
    final lookbooks = await repository.getLookbooks(agentId);
    return (products, lookbooks);
  }
}
