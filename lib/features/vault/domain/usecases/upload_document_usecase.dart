import 'dart:io';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';

class UploadDocumentUseCase {
  final VaultRepository repository;

  UploadDocumentUseCase(this.repository);

  Future<VaultDocument> call({required String userId, required File file, required String filename}) async {
    return await repository.uploadDocument(userId: userId, file: file, filename: filename);
  }
}
