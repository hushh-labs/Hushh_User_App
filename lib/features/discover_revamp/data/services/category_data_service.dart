import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category_entity.dart';
import '../models/category_model.dart';

class CategoryDataService {
  final FirebaseFirestore _firestore;
  final Map<String, CategoryEntity> _categoryCache = {};

  CategoryDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<CategoryEntity>> getCategoriesByIds(
    List<String> categoryIds,
  ) async {
    if (categoryIds.isEmpty) return [];

    final List<CategoryEntity> categories = [];
    final List<String> uncachedIds = [];

    // Check cache first
    for (final id in categoryIds) {
      if (_categoryCache.containsKey(id)) {
        categories.add(_categoryCache[id]!);
      } else {
        uncachedIds.add(id);
      }
    }

    // Fetch uncached categories
    if (uncachedIds.isNotEmpty) {
      try {
        for (final id in uncachedIds) {
          final doc = await _firestore
              .collection('agent_categories')
              .doc(id)
              .get();

          if (doc.exists) {
            final data = {...doc.data()!, 'id': doc.id};
            final model = CategoryModel.fromFirestore(data);
            final entity = model.toEntity();

            _categoryCache[id] = entity;
            categories.add(entity);
          }
        }
      } catch (e) {
        throw Exception('Failed to fetch categories: $e');
      }
    }

    return categories;
  }

  Future<CategoryEntity?> getCategoryById(String categoryId) async {
    if (_categoryCache.containsKey(categoryId)) {
      return _categoryCache[categoryId];
    }

    try {
      final doc = await _firestore
          .collection('agent_categories')
          .doc(categoryId)
          .get();

      if (!doc.exists) return null;

      final data = {...doc.data()!, 'id': doc.id};
      final model = CategoryModel.fromFirestore(data);
      final entity = model.toEntity();

      _categoryCache[categoryId] = entity;
      return entity;
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  Future<List<CategoryEntity>> getAllCategories() async {
    try {
      final qs = await _firestore.collection('agent_categories').get();

      final categories = <CategoryEntity>[];
      for (final doc in qs.docs) {
        final data = {...doc.data(), 'id': doc.id};
        final model = CategoryModel.fromFirestore(data);
        final entity = model.toEntity();

        _categoryCache[doc.id] = entity;
        categories.add(entity);
      }

      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  void clearCache() {
    _categoryCache.clear();
  }
}
