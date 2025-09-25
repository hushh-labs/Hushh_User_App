import '../repositories/checkout_repository.dart';

class GetUserBasicInfo {
  final CheckoutRepository repository;

  GetUserBasicInfo(this.repository);

  Future<Map<String, String?>> call(String uid) async {
    return await repository.getUserBasicInfo(uid);
  }
}
