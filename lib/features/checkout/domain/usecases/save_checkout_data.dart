import '../entities/checkout_entity.dart';
import '../repositories/checkout_repository.dart';

class SaveCheckoutData {
  final CheckoutRepository repository;

  SaveCheckoutData(this.repository);

  Future<void> call(String uid, CheckoutEntity data) async {
    await repository.saveCheckoutData(uid, data);
  }
}
