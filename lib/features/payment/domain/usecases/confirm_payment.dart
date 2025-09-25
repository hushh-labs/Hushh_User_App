import '../repositories/payment_repository.dart';

class ConfirmPayment {
  final PaymentRepository repository;

  ConfirmPayment(this.repository);

  Future<bool> call(String paymentIntentClientSecret) async {
    return await repository.confirmPayment(paymentIntentClientSecret);
  }
}
