import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agent_model.dart';
import '../models/agent_product_model.dart';

abstract class FirebaseDiscoverDataSource {
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

class FirebaseDiscoverDataSourceImpl implements FirebaseDiscoverDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<AgentModel>> getAgents() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('Hushhagents')
          .get();

      final agents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AgentModel.fromJson(data);
      }).toList();

      // Filter active and complete agents in the app
      return agents
          .where((agent) => agent.isActive && agent.isProfileComplete)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch agents: $e');
    }
  }

  @override
  Future<List<AgentProductModel>> getAgentProducts(String agentId) async {
    try {
      // Fetch from subcollection: Hushhagents/{agentId}/agentProducts
      final QuerySnapshot snapshot = await _firestore
          .collection('Hushhagents')
          .doc(agentId)
          .collection('agentProducts')
          .get(); // Removed isAvailable filter

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID as product ID
        return AgentProductModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch agent products: $e');
    }
  }

  @override
  Future<List<AgentProductModel>> getAllProducts() async {
    try {
      // Get all agents first
      final agents = await getAgents();
      final List<AgentProductModel> allProducts = [];

      // Fetch products from each agent's subcollection
      for (final agent in agents) {
        try {
          final products = await getAgentProducts(agent.agentId);
          allProducts.addAll(products);
        } catch (e) {
          // Skip agents with no products or errors
          continue;
        }
      }

      return allProducts;
    } catch (e) {
      throw Exception('Failed to fetch all products: $e');
    }
  }

  @override
  Future<List<AgentModel>> getAgentsPaginated(int offset, int limit) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('Hushhagents')
          .get();

      final agents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AgentModel.fromJson(data);
      }).toList();

      // Filter active and complete agents in the app
      final filteredAgents = agents
          .where((agent) => agent.isActive && agent.isProfileComplete)
          .toList();

      // Sort by createdAt in descending order in the app
      filteredAgents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply pagination manually
      return filteredAgents.skip(offset).take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch agents paginated: $e');
    }
  }

  @override
  Future<List<AgentProductModel>> getAgentProductsPaginated(
    String agentId,
    int offset,
    int limit,
  ) async {
    try {
      // Fetch from subcollection: Hushhagents/{agentId}/agentProducts
      final QuerySnapshot snapshot = await _firestore
          .collection('Hushhagents')
          .doc(agentId)
          .collection('agentProducts')
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID as product ID
        return AgentProductModel.fromJson(data);
      }).toList();

      // Sort by createdAt in descending order in the app
      products.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );

      // Apply pagination manually
      return products.skip(offset).take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch agent products paginated: $e');
    }
  }
}
