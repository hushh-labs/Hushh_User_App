import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/agent_product_revamp.dart';
import '../../domain/entities/lookbook_revamp.dart';
import 'agent_profile_local_data_source.dart';

class AgentProfileFirestoreDataSource implements AgentProfileLocalDataSource {
  final FirebaseFirestore _firestore;

  AgentProfileFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String agentsCollection = 'Hushhagents';
  static const String agentProductsSubcollection = 'agentProducts';

  @override
  Future<List<AgentProductRevamp>> getProducts(String agentId) async {
    final snap = await _firestore
        .collection(agentsCollection)
        .doc(agentId)
        .collection(agentProductsSubcollection)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      final List<dynamic> imageUrlsDyn =
          (data['imageUrls'] as List<dynamic>?) ?? const [];
      final List<String> imageUrls = imageUrlsDyn
          .map((e) => e.toString())
          .toList();
      final List<dynamic> highlightsDyn =
          (data['highlights'] as List<dynamic>?) ?? const [];
      final List<String> highlights = highlightsDyn
          .map((e) => e.toString())
          .toList();
      final Map<String, String> attributes =
          ((data['attributes'] as Map<String, dynamic>?) ?? <String, dynamic>{})
              .map(
                (key, value) =>
                    MapEntry(key.toString(), value?.toString() ?? ''),
              );
      final List<String> categories =
          ((data['categories'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString())
              .toList();
      final List<String> tags = ((data['tags'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList();
      final List<String> lookbookIds =
          ((data['lookbookIds'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString())
              .toList();

      DateTime parseDate(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
        return DateTime.now();
      }

      return AgentProductRevamp(
        id: data['id']?.toString() ?? d.id,
        sku: data['sku']?.toString() ?? '',
        agentId: data['agentId']?.toString() ?? agentId,
        brand: data['brand']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        subtitle: data['subtitle']?.toString() ?? '',
        shortDescription: data['shortDescription']?.toString() ?? '',
        longDescription: data['longDescription']?.toString() ?? '',
        highlights: highlights,
        imageUrls: imageUrls,
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        currency: data['currency']?.toString() ?? 'USD',
        mrp:
            (data['mrp'] as num?)?.toDouble() ??
            (data['price'] as num?)?.toDouble() ??
            0.0,
        discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0.0,
        stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
        availability: data['availability']?.toString() ?? 'in_stock',
        attributes: attributes,
        categories: categories,
        tags: tags,
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
        lookbookIds: lookbookIds,
        createdAt: parseDate(data['createdAt']),
        updatedAt: parseDate(data['updatedAt']),
        publishedAt: parseDate(data['publishedAt']),
      );
    }).toList();
  }

  @override
  Future<List<LookbookRevamp>> getLookbooks(String agentId) async {
    // If you later add lookbooks, read them here. For now return empty.
    return const [];
  }
}
