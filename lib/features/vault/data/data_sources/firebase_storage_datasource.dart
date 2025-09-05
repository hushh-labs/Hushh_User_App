import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

abstract class FirebaseStorageDataSource {
  Future<String> uploadFile(
      {required String userId, required File file, required String filename});
  Future<void> deleteFile({required String filePath});
}

class FirebaseStorageDataSourceImpl implements FirebaseStorageDataSource {
  final FirebaseStorage _firebaseStorage;

  FirebaseStorageDataSourceImpl({FirebaseStorage? firebaseStorage})
      : _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadFile(
      {required String userId, required File file, required String filename}) async {
    try {
      final ref = _firebaseStorage.ref().child('vault/$userId/$filename');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage Error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error during file upload: $e');
    }
  }

  @override
  Future<void> deleteFile({required String filePath}) async {
    try {
      final ref = _firebaseStorage.refFromURL(filePath);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage Error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error during file deletion: $e');
    }
  }
}
