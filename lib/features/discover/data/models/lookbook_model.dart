import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LookbookModel extends Equatable {
  final String id;
  final String lookbookName;
  final String description;
  final String agentId;
  final List<String> products;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LookbookModel({
    required this.id,
    required this.lookbookName,
    required this.description,
    required this.agentId,
    required this.products,
    required this.createdAt,
    this.updatedAt,
  });

  factory LookbookModel.fromJson(String id, Map<String, dynamic> json) {
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

    return LookbookModel(
      id: id,
      lookbookName: json['lookbookName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      agentId: json['agentId']?.toString() ?? '',
      products: List<String>.from(json['products'] ?? []),
      createdAt: parseFirestoreDate(json['createdAt']),
      updatedAt: parseFirestoreDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lookbookName': lookbookName,
      'description': description,
      'agentId': agentId,
      'products': products,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    lookbookName,
    description,
    agentId,
    products,
    createdAt,
    updatedAt,
  ];
}
