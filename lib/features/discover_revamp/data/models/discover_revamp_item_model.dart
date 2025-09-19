import '../../domain/entities/discover_revamp_item.dart';

class DiscoverRevampItemModel extends DiscoverRevampItem {
  const DiscoverRevampItemModel({
    required super.id,
    required super.title,
    super.imageUrl,
  });

  factory DiscoverRevampItemModel.fromMap(Map<String, dynamic> map) {
    return DiscoverRevampItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
  };
}
