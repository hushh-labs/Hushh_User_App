import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/agent_entity.dart';
import '../models/agent_model.dart';

class AgentDataService {
  final FirebaseFirestore _firestore;

  AgentDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<AgentEntity>> getActiveAgents() async {
    try {
      final qs = await _firestore
          .collection('Hushhagents')
          .where('isActive', isEqualTo: true)
          .where('isProfileComplete', isEqualTo: true)
          .get();

      final agents = <AgentEntity>[];
      for (final doc in qs.docs) {
        final data = {...doc.data(), 'id': doc.id};
        final model = AgentModel.fromFirestore(data);
        agents.add(model.toEntity());
      }

      return agents;
    } catch (e) {
      throw Exception('Failed to fetch agents: $e');
    }
  }

  Future<AgentEntity?> getAgentById(String agentId) async {
    try {
      final doc = await _firestore.collection('Hushhagents').doc(agentId).get();

      if (!doc.exists) return null;

      final data = {...doc.data()!, 'id': doc.id};
      final model = AgentModel.fromFirestore(data);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to fetch agent: $e');
    }
  }
}
