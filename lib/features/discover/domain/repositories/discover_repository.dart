import '../../data/models/agent_model.dart';
import '../../data/models/agent_product_model.dart';

abstract class DiscoverRepository {
  Future<List<AgentModel>> getAgents();
  Future<List<AgentProductModel>> getAgentProducts(String agentId);
  Future<List<AgentProductModel>> getAllProducts();

  // Pagination methods
  Future<List<AgentModel>> getAgentsPaginated(int offset, int limit);
  Future<List<AgentProductModel>> getAgentProductsPaginated(
    String agentId,
    int offset,
    int limit,
  );
}
