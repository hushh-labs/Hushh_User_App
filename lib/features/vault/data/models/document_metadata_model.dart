import 'package:hushh_user_app/features/vault/domain/entities/document_metadata.dart';

class DocumentMetadataModel extends DocumentMetadata {
  const DocumentMetadataModel({
    required super.title,
    required super.description,
    required super.tags,
    required super.category,
  });

  factory DocumentMetadataModel.fromMap(Map<String, dynamic> map) {
    return DocumentMetadataModel(
      title: map['title'] as String,
      description: map['description'] as String,
      tags: List<String>.from(map['tags'] as List),
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'tags': tags,
      'category': category,
    };
  }
}
