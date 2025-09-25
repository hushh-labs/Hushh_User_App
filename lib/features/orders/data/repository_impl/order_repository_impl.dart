import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../data_sources/orders_firebase_data_source.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrdersFirebaseDataSource dataSource;

  OrderRepositoryImpl(this.dataSource);

  @override
  Future<String> createOrder(OrderEntity order) async {
    try {
      final orderModel = OrderModel.fromEntity(order);
      return await dataSource.createOrder(orderModel);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Future<OrderEntity?> getOrder(String orderId) async {
    try {
      final orderModel = await dataSource.getOrder(orderId);
      return orderModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  @override
  Future<List<OrderEntity>> getUserOrders(String userId) async {
    try {
      final orderModels = await dataSource.getUserOrders(userId);
      return orderModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await dataSource.updateOrderStatus(orderId, status);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
