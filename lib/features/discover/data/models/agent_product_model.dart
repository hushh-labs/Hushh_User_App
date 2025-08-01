import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgentProductModel extends Equatable {
  final String id;
  final String productName;
  final String? productDescription;
  final double productPrice;
  final String? productCurrency;
  final String? productImage;
  final String? productSkuUniqueId;
  final int stockQuantity;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final List<String>? lookbookIds;

  const AgentProductModel({
    required this.id,
    required this.productName,
    this.productDescription,
    required this.productPrice,
    this.productCurrency,
    this.productImage,
    this.productSkuUniqueId,
    required this.stockQuantity,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.lookbookIds,
  });

  factory AgentProductModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseFirestoreDate(dynamic dateField) {
      if (dateField == null) return null;

      if (dateField is Timestamp) {
        return dateField.toDate();
      } else if (dateField is String) {
        try {
          return DateTime.parse(dateField);
        } catch (e) {
          print('Failed to parse product date string: $dateField, error: $e');
          return null;
        }
      } else if (dateField is DateTime) {
        return dateField;
      }

      print(
        'Unknown product date field type: ${dateField.runtimeType}, value: $dateField',
      );
      return null;
    }

    return AgentProductModel(
      id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productDescription: json['productDescription']?.toString(),
      productPrice: (json['productPrice'] as num?)?.toDouble() ?? 0.0,
      productCurrency: json['productCurrency']?.toString(),
      productImage: json['productImage']?.toString(),
      productSkuUniqueId: json['productSkuUniqueId']?.toString(),
      stockQuantity: json['stockQuantity'] as int? ?? 0,
      category: json['category']?.toString(),
      createdAt: parseFirestoreDate(json['createdAt']),
      updatedAt: parseFirestoreDate(json['updatedAt']),
      createdBy: json['createdBy']?.toString(),
      lookbookIds: json['lookbookIds'] != null
          ? List<String>.from(json['lookbookIds'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'productDescription': productDescription,
      'productPrice': productPrice,
      'productCurrency': productCurrency,
      'productImage': productImage,
      'productSkuUniqueId': productSkuUniqueId,
      'stockQuantity': stockQuantity,
      'category': category,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'lookbookIds': lookbookIds,
    };
  }

  AgentProductModel copyWith({
    String? id,
    String? productName,
    String? productDescription,
    double? productPrice,
    String? productCurrency,
    String? productImage,
    String? productSkuUniqueId,
    int? stockQuantity,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? lookbookIds,
  }) {
    return AgentProductModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productPrice: productPrice ?? this.productPrice,
      productCurrency: productCurrency ?? this.productCurrency,
      productImage: productImage ?? this.productImage,
      productSkuUniqueId: productSkuUniqueId ?? this.productSkuUniqueId,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lookbookIds: lookbookIds ?? this.lookbookIds,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productName,
    productDescription,
    productPrice,
    productCurrency,
    productImage,
    productSkuUniqueId,
    stockQuantity,
    category,
    createdAt,
    updatedAt,
    createdBy,
    lookbookIds,
  ];

  // Backward compatibility getters for existing UI components
  String? get imageUrl => productImage;
  double get price => productPrice;
  String? get description => productDescription;
}
