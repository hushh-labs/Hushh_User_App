import '../../domain/entities/checkout_entity.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../data_sources/checkout_firebase_data_source.dart';
import '../models/checkout_model.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutFirebaseDataSource dataSource;

  CheckoutRepositoryImpl(this.dataSource);

  @override
  Future<CheckoutEntity?> getCheckoutData(String uid) async {
    try {
      final model = await dataSource.getCheckoutData(uid);
      return model?.toEntity();
    } catch (e) {
      throw Exception('Failed to get checkout data: $e');
    }
  }

  @override
  Future<void> saveCheckoutData(String uid, CheckoutEntity data) async {
    try {
      final model = CheckoutModel.fromEntity(
        data.copyWith(lastUpdated: DateTime.now()),
      );
      await dataSource.saveCheckoutData(uid, model);
    } catch (e) {
      throw Exception('Failed to save checkout data: $e');
    }
  }

  @override
  Future<Map<String, String?>> getUserBasicInfo(String uid) async {
    try {
      return await dataSource.getUserBasicInfo(uid);
    } catch (e) {
      throw Exception('Failed to get user basic info: $e');
    }
  }
}
