import 'package:equatable/equatable.dart';

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
    return AgentModel(
      agentId: json['agentId']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'brand': brand,
      'brandName': brandName,
      'categories': categories,
      'createdAt': createdAt,
      'email': email,
      'fullName': fullName,
      'isActive': isActive,
      'isProfileComplete': isProfileComplete,
      'name': name,
      'phone': phone,
      'updatedAt': updatedAt,
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
