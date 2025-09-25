import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_entity.dart';

class OrderModel {
  final String id;
  final String userId;
  final String agentId;
  final String agentName;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String currency;
  final AddressModel deliveryAddress;
  final PaymentDetailsModel paymentDetails;
  final String status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.agentName,
    required this.items,
    required this.totalAmount,
    required this.currency,
    required this.deliveryAddress,
    required this.paymentDetails,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      userId: entity.userId,
      agentId: entity.agentId,
      agentName: entity.agentName,
      items: entity.items
          .map((item) => OrderItemModel.fromEntity(item))
          .toList(),
      totalAmount: entity.totalAmount,
      currency: entity.currency,
      deliveryAddress: AddressModel.fromEntity(entity.deliveryAddress),
      paymentDetails: PaymentDetailsModel.fromEntity(entity.paymentDetails),
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] as String,
      agentId: data['agentId'] as String,
      agentName: data['agentName'] as String,
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      currency: data['currency'] as String,
      deliveryAddress: AddressModel.fromMap(
        data['deliveryAddress'] as Map<String, dynamic>,
      ),
      paymentDetails: PaymentDetailsModel.fromMap(
        data['paymentDetails'] as Map<String, dynamic>,
      ),
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'agentId': agentId,
      'agentName': agentName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'currency': currency,
      'deliveryAddress': deliveryAddress.toMap(),
      'paymentDetails': paymentDetails.toMap(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      userId: userId,
      agentId: agentId,
      agentName: agentName,
      items: items.map((item) => item.toEntity()).toList(),
      totalAmount: totalAmount,
      currency: currency,
      deliveryAddress: deliveryAddress.toEntity(),
      paymentDetails: paymentDetails.toEntity(),
      status: status,
      createdAt: createdAt,
    );
  }
}

class OrderItemModel {
  final String productId;
  final String productName;
  final String? description;
  final String? imageUrl;
  final double price;
  final int quantity;
  final double totalPrice;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    this.description,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      productId: entity.productId,
      productName: entity.productName,
      description: entity.description,
      imageUrl: entity.imageUrl,
      price: entity.price,
      quantity: entity.quantity,
      totalPrice: entity.totalPrice,
    );
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      totalPrice: (map['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      productId: productId,
      productName: productName,
      description: description,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity,
      totalPrice: totalPrice,
    );
  }
}

class AddressModel {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? fullName;
  final String? phoneNumber;

  const AddressModel({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.fullName,
    this.phoneNumber,
  });

  factory AddressModel.fromEntity(AddressEntity entity) {
    return AddressModel(
      street: entity.street,
      city: entity.city,
      state: entity.state,
      postalCode: entity.postalCode,
      country: entity.country,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
    );
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      street: map['street'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      postalCode: map['postalCode'] as String,
      country: map['country'] as String,
      fullName: map['fullName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };
  }

  AddressEntity toEntity() {
    return AddressEntity(
      street: street,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}

class PaymentDetailsModel {
  final String paymentId;
  final String orderId;
  final String? signature;
  final String method;
  final String status;
  final double amount;
  final String currency;
  final DateTime? paidAt;

  const PaymentDetailsModel({
    required this.paymentId,
    required this.orderId,
    this.signature,
    required this.method,
    required this.status,
    required this.amount,
    required this.currency,
    this.paidAt,
  });

  factory PaymentDetailsModel.fromEntity(PaymentDetailsEntity entity) {
    return PaymentDetailsModel(
      paymentId: entity.paymentId,
      orderId: entity.orderId,
      signature: entity.signature,
      method: entity.method,
      status: entity.status,
      amount: entity.amount,
      currency: entity.currency,
      paidAt: entity.paidAt,
    );
  }

  factory PaymentDetailsModel.fromMap(Map<String, dynamic> map) {
    return PaymentDetailsModel(
      paymentId: map['paymentId'] as String,
      orderId: map['orderId'] as String,
      signature: map['signature'] as String?,
      method: map['method'] as String,
      status: map['status'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'method': method,
      'status': status,
      'amount': amount,
      'currency': currency,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  PaymentDetailsEntity toEntity() {
    return PaymentDetailsEntity(
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
      method: method,
      status: status,
      amount: amount,
      currency: currency,
      paidAt: paidAt,
    );
  }
}
