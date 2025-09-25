import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<String> createOrder(OrderEntity order);
  Future<OrderEntity?> getOrder(String orderId);
  Future<List<OrderEntity>> getUserOrders(String userId);
  Future<void> updateOrderStatus(String orderId, String status);
}
