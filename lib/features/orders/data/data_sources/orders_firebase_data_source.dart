import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

abstract class OrdersFirebaseDataSource {
  Future<String> createOrder(OrderModel order);
  Future<OrderModel?> getOrder(String orderId);
  Future<List<OrderModel>> getUserOrders(String userId);
  Future<void> updateOrderStatus(String orderId, String status);
}

class OrdersFirebaseDataSourceImpl implements OrdersFirebaseDataSource {
  final FirebaseFirestore _firestore;

  OrdersFirebaseDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await _firestore
          .collection('orders')
          .add(order.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  @override
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
