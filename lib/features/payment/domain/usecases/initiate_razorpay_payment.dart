import 'package:dartz/dartz.dart';
import '../repositories/payment_repository.dart';
import '../../data/models/razorpay_request_model.dart';

class InitiateRazorpayPayment {
  final PaymentRepository repository;

  InitiateRazorpayPayment(this.repository);

  Future<Either<String, Map<String, dynamic>>> call(
    RazorpayRequestModel request,
  ) async {
    try {
      final result = await repository.initiateRazorpayPayment(request);
      return Right(result);
    } catch (e) {
      return Left('Failed to initiate Razorpay payment: ${e.toString()}');
    }
  }
}
