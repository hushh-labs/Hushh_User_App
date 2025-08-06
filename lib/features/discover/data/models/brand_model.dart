import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandModel extends Equatable {
  final String id;
  final String brandName;
  final String hexCode;
  final String iconLink;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BrandModel({
    required this.id,
    required this.brandName,
    required this.hexCode,
    required this.iconLink,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json, String documentId) {
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

    return BrandModel(
      id: documentId,
      brandName: json['brandName']?.toString() ?? '',
      hexCode: json['hexCode']?.toString() ?? '#000000',
      iconLink: json['iconLink']?.toString() ?? '',
      createdAt: parseFirestoreDate(json['createdAt']),
      updatedAt: parseFirestoreDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandName': brandName,
      'hexCode': hexCode,
      'iconLink': iconLink,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BrandModel copyWith({
    String? id,
    String? brandName,
    String? hexCode,
    String? iconLink,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      hexCode: hexCode ?? this.hexCode,
      iconLink: iconLink ?? this.iconLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    brandName,
    hexCode,
    iconLink,
    createdAt,
    updatedAt,
  ];
}
