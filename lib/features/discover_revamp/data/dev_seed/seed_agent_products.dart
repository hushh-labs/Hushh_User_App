import 'package:cloud_firestore/cloud_firestore.dart';
import 'iphone_seed_data.dart';

/// Dev-only utility to seed `agentProducts` subcollections under every doc
/// in the `hushhagents` collection. Safe to run once; uses merge writes.
Future<void> seedAllAgentsWithIphones({bool normalizeAgentId = true}) async {
  final db = FirebaseFirestore.instance;
  final agents = await db.collection('hushhagents').get();

  for (final agent in agents.docs) {
    final agentId = agent.id;
    WriteBatch batch = db.batch();
    int count = 0;

    for (final p in iphoneSeedProducts) {
      final data = Map<String, dynamic>.from(p);
      if (normalizeAgentId) data['agentId'] = agentId;

      // Convert RFC3339 timestamps to Firestore Timestamps
      Timestamp asTs(String key) =>
          Timestamp.fromDate(DateTime.parse(data[key] as String));
      data['createdAt'] = asTs('createdAt');
      data['updatedAt'] = asTs('updatedAt');
      data['publishedAt'] = asTs('publishedAt');

      final ref = db
          .collection('hushhagents')
          .doc(agentId)
          .collection('agentProducts')
          .doc(data['id'] as String);

      batch.set(ref, data, SetOptions(merge: true));
      if (++count % 450 == 0) {
        await batch.commit();
        batch = db.batch();
      }
    }

    if (count % 450 != 0) {
      await batch.commit();
    }
  }
}
