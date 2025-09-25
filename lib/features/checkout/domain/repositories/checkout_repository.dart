import '../entities/checkout_entity.dart';

abstract class CheckoutRepository {
  /// Get checkout data for a specific user
  Future<CheckoutEntity?> getCheckoutData(String uid);

  /// Save checkout data for a specific user
  Future<void> saveCheckoutData(String uid, CheckoutEntity data);

  /// Get user basic info (fullname and email) from HushUsers
  Future<Map<String, String?>> getUserBasicInfo(String uid);
}
