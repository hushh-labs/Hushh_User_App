import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';

class GetDocumentsUseCase {
  final VaultRepository repository;

  GetDocumentsUseCase(this.repository);

  Future<List<VaultDocument>> call({required String userId}) async {
    return await repository.getDocuments(userId: userId);
  }
}
