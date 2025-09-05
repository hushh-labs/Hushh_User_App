import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';

class ExtractDocumentContentUseCase {
  final VaultRepository repository;

  ExtractDocumentContentUseCase(this.repository);

  Future<VaultDocument> call({required String documentId}) async {
    return await repository.extractDocumentContent(documentId: documentId);
  }
}
