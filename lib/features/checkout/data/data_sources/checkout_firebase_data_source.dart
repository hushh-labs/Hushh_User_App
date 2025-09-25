import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checkout_model.dart';

abstract class CheckoutFirebaseDataSource {
  Future<CheckoutModel?> getCheckoutData(String uid);
  Future<void> saveCheckoutData(String uid, CheckoutModel data);
  Future<Map<String, String?>> getUserBasicInfo(String uid);
}

class CheckoutFirebaseDataSourceImpl implements CheckoutFirebaseDataSource {
  final FirebaseFirestore firestore;

  CheckoutFirebaseDataSourceImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<CheckoutModel?> getCheckoutData(String uid) async {
    try {
      final doc = await firestore
          .collection('HushUsers')
          .doc(uid)
          .collection('CheckoutDetails')
          .doc('user_checkout_data')
          .get();

      if (doc.exists && doc.data() != null) {
        return CheckoutModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get checkout data: $e');
    }
  }

  @override
  Future<void> saveCheckoutData(String uid, CheckoutModel data) async {
    try {
      await firestore
          .collection('HushUsers')
          .doc(uid)
          .collection('CheckoutDetails')
          .doc('user_checkout_data')
          .set(data.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save checkout data: $e');
    }
  }

  @override
  Future<Map<String, String?>> getUserBasicInfo(String uid) async {
    try {
      final doc = await firestore.collection('HushUsers').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'fullName': data['fullName'] as String?,
          'email': data['email'] as String?,
        };
      }
      return {'fullName': null, 'email': null};
    } catch (e) {
      throw Exception('Failed to get user basic info: $e');
    }
  }
}
