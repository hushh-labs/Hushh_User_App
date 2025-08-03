import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgentModel extends Equatable {
  final String agentId;
  final String brand;
  final String brandName;
  final List<String> categories;
  final DateTime createdAt;
  final String email;
  final String fullName;
  final bool isActive;
  final bool isProfileComplete;
  final String name;
  final String phone;
  final DateTime updatedAt;

  const AgentModel({
    required this.agentId,
    required this.brand,
    required this.brandName,
    required this.categories,
    required this.createdAt,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.isProfileComplete,
    required this.name,
    required this.phone,
    required this.updatedAt,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
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

    return AgentModel(
      agentId: json['agentId']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      createdAt: parseFirestoreDate(json['createdAt']),
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      updatedAt: parseFirestoreDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'brand': brand,
      'brandName': brandName,
      'categories': categories,
      'createdAt': createdAt.toIso8601String(),
      'email': email,
      'fullName': fullName,
      'isActive': isActive,
      'isProfileComplete': isProfileComplete,
      'name': name,
      'phone': phone,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AgentModel copyWith({
    String? agentId,
    String? brand,
    String? brandName,
    List<String>? categories,
    DateTime? createdAt,
    String? email,
    String? fullName,
    bool? isActive,
    bool? isProfileComplete,
    String? name,
    String? phone,
    DateTime? updatedAt,
  }) {
    return AgentModel(
      agentId: agentId ?? this.agentId,
      brand: brand ?? this.brand,
      brandName: brandName ?? this.brandName,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    agentId,
    brand,
    brandName,
    categories,
    createdAt,
    email,
    fullName,
    isActive,
    isProfileComplete,
    name,
    phone,
    updatedAt,
  ];
}
