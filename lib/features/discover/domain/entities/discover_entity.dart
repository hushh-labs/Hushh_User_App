import 'package:equatable/equatable.dart';

class DiscoverEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final double rating;
  final int views;
  final DateTime createdAt;

  const DiscoverEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.views,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    category,
    rating,
    views,
    createdAt,
  ];

  DiscoverEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    double? rating,
    int? views,
    DateTime? createdAt,
  }) {
    return DiscoverEntity(
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

class DiscoverCategoryEntity extends Equatable {
  final String id;
  final String name;
  final String icon;
  final bool isSelected;

  const DiscoverCategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    this.isSelected = false,
  });

  @override
  List<Object?> get props => [id, name, icon, isSelected];

  DiscoverCategoryEntity copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isSelected,
  }) {
    return DiscoverCategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
