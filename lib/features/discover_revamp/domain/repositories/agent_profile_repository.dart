import '../entities/agent_product_revamp.dart';
import '../entities/lookbook_revamp.dart';

abstract class AgentProfileRepository {
  Future<List<AgentProductRevamp>> getProducts(String agentId);
  Future<List<LookbookRevamp>> getLookbooks(String agentId);
}
