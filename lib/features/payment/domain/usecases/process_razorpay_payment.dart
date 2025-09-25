import 'package:dartz/dartz.dart';
import '../repositories/payment_repository.dart';
import '../entities/razorpay_payment_entity.dart';

class ProcessRazorpayPayment {
  final PaymentRepository repository;

  ProcessRazorpayPayment(this.repository);

  Future<Either<String, RazorpayPaymentEntity>> call(
    Map<String, dynamic> paymentResponse,
    double amount,
    String currency,
  ) async {
    try {
      final result = await repository.processRazorpayPayment(
        paymentResponse,
        amount,
        currency,
      );
      return Right(result);
    } catch (e) {
      return Left('Failed to process Razorpay payment: ${e.toString()}');
    }
  }
}
