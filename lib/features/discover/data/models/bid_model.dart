import 'package:equatable/equatable.dart';

class BidModel extends Equatable {
  final String id;
  final String agentId;
  final String agentName;
  final double bidAmount;
  final DateTime createdAt;
  final String productId;
  final String productName;
  final String productPrice;
  final String quantity;
  final String status;
  final DateTime updatedAt;
  final String userId;
  final String userName;
  final DateTime validity;

  const BidModel({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.bidAmount,
    required this.createdAt,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.status,
    required this.updatedAt,
    required this.userId,
    required this.userName,
    required this.validity,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'] ?? '',
      agentId: json['agentId'] ?? '',
      agentName: json['agentName'] ?? '',
      bidAmount: (json['bidAmount'] is int)
          ? (json['bidAmount'] as int).toDouble()
          : (json['bidAmount'] as num).toDouble(),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productPrice: json['productPrice'] ?? '',
      quantity: json['quantity'] ?? '',
      status: json['status'] ?? '',
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      validity: DateTime.parse(
        json['validity'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'agentName': agentName,
      'bidAmount': bidAmount,
      'createdAt': createdAt.toIso8601String(),
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'quantity': quantity,
      'status': status,
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'validity': validity.toIso8601String(),
    };
  }

  bool get isValid {
    final now = DateTime.now();
    return status == 'pending' && validity.isAfter(now);
  }

  @override
  List<Object?> get props => [
    id,
    agentId,
    agentName,
    bidAmount,
    createdAt,
    productId,
    productName,
    productPrice,
    quantity,
    status,
    updatedAt,
    userId,
    userName,
    validity,
  ];
}
