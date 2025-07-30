import '../../domain/repositories/discover_repository.dart';
import '../datasources/firebase_discover_datasource.dart';
import '../models/agent_model.dart';
import '../models/agent_product_model.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  final FirebaseDiscoverDataSource _dataSource;

  DiscoverRepositoryImpl(this._dataSource);

  @override
  Future<List<AgentModel>> getAgents() async {
    try {
      return await _dataSource.getAgents();
    } catch (e) {
      throw Exception('Failed to get agents: $e');
    }
  }

  @override
  Future<List<AgentProductModel>> getAgentProducts(String agentId) async {
    try {
      return await _dataSource.getAgentProducts(agentId);
    } catch (e) {
      throw Exception('Failed to get agent products: $e');
    }
  }

  @override
  Future<List<AgentProductModel>> getAllProducts() async {
    try {
      return await _dataSource.getAllProducts();
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }

  @override
  Future<List<AgentModel>> getAgentsPaginated(int offset, int limit) async {
    try {
      return await _dataSource.getAgentsPaginated(offset, limit);
    } catch (e) {
      throw Exception('Failed to get agents paginated: $e');
    }
  }

  @override
  Future<List<AgentProductModel>> getAgentProductsPaginated(
    String agentId,
    int offset,
    int limit,
  ) async {
    try {
      return await _dataSource.getAgentProductsPaginated(
        agentId,
        offset,
        limit,
      );
    } catch (e) {
      throw Exception('Failed to get agent products paginated: $e');
    }
  }
}
