import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';

class DeleteDocumentUseCase {
  final VaultRepository repository;

  DeleteDocumentUseCase(this.repository);

  Future<void> call({required String userId, required String documentId}) async {
    return await repository.deleteDocument(userId: userId, documentId: documentId);
  }
}
