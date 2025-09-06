import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hushh_user_app/features/vault/data/services/supabase_document_context_prewarm_service.dart';
import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';

/// Service to prewarm vault context on app startup
class VaultStartupPrewarmService {
  final SupabaseDocumentContextPrewarmService _documentPrewarmService;
  final VaultRepository _vaultRepository;
  final FirebaseAuth _auth;

  VaultStartupPrewarmService({
    required SupabaseDocumentContextPrewarmService documentPrewarmService,
    required VaultRepository vaultRepository,
    FirebaseAuth? auth,
  }) : _documentPrewarmService = documentPrewarmService,
       _vaultRepository = vaultRepository,
       _auth = auth ?? FirebaseAuth.instance;

  /// Prewarm vault context on app startup
  Future<void> prewarmVaultOnStartup() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint(
          '🗄️ [VAULT STARTUP] User not authenticated, skipping vault prewarming',
        );
        return;
      }

      final userId = currentUser.uid;
      debugPrint(
        '🗄️ [VAULT STARTUP] Starting vault context prewarming for user: $userId',
      );

      // Get all user documents
      final documents = await _vaultRepository.getDocuments(userId: userId);

      if (documents.isEmpty) {
        debugPrint(
          '🗄️ [VAULT STARTUP] No documents found, skipping vault prewarming',
        );
        return;
      }

      debugPrint(
        '🗄️ [VAULT STARTUP] Found ${documents.length} documents, prewarming context...',
      );

      // Prewarm context with the first document (this will build context for all documents)
      await _documentPrewarmService.prewarmDocumentContext(
        userId: userId,
        document: documents.first,
      );

      debugPrint(
        '🗄️ [VAULT STARTUP] ✅ Vault context prewarming completed successfully',
      );
    } catch (e) {
      debugPrint('🗄️ [VAULT STARTUP] ⚠️ Vault context prewarming failed: $e');
      // Don't throw error as this is a background operation
    }
  }

  /// Refresh vault context (can be called when documents are updated externally)
  Future<void> refreshVaultContext() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint(
          '🗄️ [VAULT REFRESH] User not authenticated, skipping vault refresh',
        );
        return;
      }

      final userId = currentUser.uid;
      debugPrint(
        '🗄️ [VAULT REFRESH] Refreshing vault context for user: $userId',
      );

      await prewarmVaultOnStartup();

      debugPrint('🗄️ [VAULT REFRESH] ✅ Vault context refresh completed');
    } catch (e) {
      debugPrint('🗄️ [VAULT REFRESH] ⚠️ Vault context refresh failed: $e');
    }
  }
}
