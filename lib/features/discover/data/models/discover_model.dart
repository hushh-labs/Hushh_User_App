import '../../domain/entities/discover_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiscoverModel extends DiscoverEntity {
  const DiscoverModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.category,
    required super.rating,
    required super.views,
    required super.createdAt,
  });

  factory DiscoverModel.fromJson(Map<String, dynamic> json) {
    DateTime parseFirestoreDate(dynamic dateField) {
      if (dateField == null) return DateTime.now();

      if (dateField is Timestamp) {
        return dateField.toDate();
      } else if (dateField is String) {
        try {
          return DateTime.parse(dateField);
        } catch (e) {
          return DateTime.now();
        }
      } else if (dateField is DateTime) {
        return dateField;
      }

      return DateTime.now();
    }

    return DiscoverModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      views: json['views'] as int? ?? 0,
      createdAt: parseFirestoreDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'views': views,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  DiscoverModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    double? rating,
    int? views,
    DateTime? createdAt,
  }) {
    return DiscoverModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DiscoverCategoryModel extends DiscoverCategoryEntity {
  const DiscoverCategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    super.isSelected = false,
  });

  factory DiscoverCategoryModel.fromJson(Map<String, dynamic> json) {
    return DiscoverCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'isSelected': isSelected};
  }

  @override
  DiscoverCategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isSelected,
  }) {
    return DiscoverCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
