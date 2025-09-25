import '../../data/models/payment_request_model.dart';
import '../entities/payment_intent_entity.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentIntent {
  final PaymentRepository repository;

  CreatePaymentIntent(this.repository);

  Future<PaymentIntentEntity> call(PaymentRequestModel request) async {
    return await repository.createPaymentIntent(request);
  }
}
