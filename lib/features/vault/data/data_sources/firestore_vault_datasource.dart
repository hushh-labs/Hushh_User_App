import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hushh_user_app/features/vault/data/models/vault_document_model.dart';

abstract class FirestoreVaultDataSource {
  Future<VaultDocumentModel> uploadDocumentMetadata(
      {required String userId, required VaultDocumentModel document});
  Future<void> deleteDocumentMetadata({required String userId, required String documentId});
  Future<List<VaultDocumentModel>> getDocumentsMetadata({required String userId});
  Future<VaultDocumentModel> getDocumentMetadata({required String userId, required String documentId});
  Future<void> updateDocumentMetadata({required String userId, required VaultDocumentModel document});
}

class FirestoreVaultDataSourceImpl implements FirestoreVaultDataSource {
  final FirebaseFirestore _firestore;

  FirestoreVaultDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<VaultDocumentModel> uploadDocumentMetadata(
      {required String userId, required VaultDocumentModel document}) async {
    try {
      final docRef = _firestore.collection('users').doc(userId).collection('vault_documents').doc(document.id);
      await docRef.set(document.toFirestore());
      return document;
    } on FirebaseException catch (e) {
      throw Exception('Firestore Error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error during document metadata upload: $e');
    }
  }

  @override
  Future<void> deleteDocumentMetadata({required String userId, required String documentId}) async {
    try {
      await _firestore.collection('users').doc(userId).collection('vault_documents').doc(documentId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Firestore Error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error during document metadata deletion: $e');
    }
  }

  @override
  Future<List<VaultDocumentModel>> getDocumentsMetadata({required String userId}) async {
    try {
      final querySnapshot = await _firestore.collection('users').doc(userId).collection('vault_documents').get();
      return querySnapshot.docs.map((doc) => VaultDocumentModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw Exception('Firestore Error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error during fetching document metadata: $e');
    }
  }

  @override
  Future<VaultDocumentModel> getDocumentMetadata({required String userId, required String documentId}) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).collection('vault_documents').doc(documentId).get();
      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }
      return VaultDocumentModel.fromFirestore(docSnapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore Error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error during fetching single document metadata: $e');
    }
  }

  @override
  Future<void> updateDocumentMetadata({required String userId, required VaultDocumentModel document}) async {
    try {
      final docRef = _firestore.collection('users').doc(userId).collection('vault_documents').doc(document.id);
      await docRef.update(document.toFirestore());
    } on FirebaseException catch (e) {
      throw Exception('Firestore Error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error during document metadata update: $e');
    }
  }
}
