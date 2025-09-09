import 'dart:io';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';

abstract class VaultRepository {
  Future<VaultDocument> uploadDocument({
    required String userId,
    required File file,
    required String filename,
  });
  Future<void> deleteDocument({
    required String userId,
    required String documentId,
  });
  Future<List<VaultDocument>> getDocuments({required String userId});
  Future<VaultDocument> extractDocumentContent({required String documentId});
  Future<void> clearAllDocuments(String userId);
}
