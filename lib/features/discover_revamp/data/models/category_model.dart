import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category_entity.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int? order;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.order,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> doc) {
    final data = doc;

    // Handle timestamps
    DateTime? createdAt;
    DateTime? updatedAt;

    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']);
    }

    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.tryParse(data['updatedAt']);
    }

    // Handle order field which might be int or string
    int? order;
    if (data['order'] is int) {
      order = data['order'];
    } else if (data['order'] is String) {
      order = int.tryParse(data['order']);
    }

    return CategoryModel(
      id: data['id'] ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString(),
      iconUrl: data['iconUrl']?.toString(),
      order: order,
      isActive: data['isActive'] == true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
      order: order,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
