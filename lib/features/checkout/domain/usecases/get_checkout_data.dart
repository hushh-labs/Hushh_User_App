import '../entities/checkout_entity.dart';
import '../repositories/checkout_repository.dart';

class GetCheckoutData {
  final CheckoutRepository repository;

  GetCheckoutData(this.repository);

  Future<CheckoutEntity?> call(String uid) async {
    return await repository.getCheckoutData(uid);
  }
}
