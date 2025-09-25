import 'package:dartz/dartz.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CreateOrder {
  final OrderRepository repository;

  CreateOrder(this.repository);

  Future<Either<String, String>> call(OrderEntity order) async {
    try {
      final orderId = await repository.createOrder(order);
      return Right(orderId);
    } catch (e) {
      return Left('Failed to create order: ${e.toString()}');
    }
  }
}
