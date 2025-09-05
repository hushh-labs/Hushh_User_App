import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';

abstract class SupabaseDocumentContextPrewarmService {
  Future<void> prewarmDocumentContext({
    required String userId,
    required VaultDocument document,
  });
  Future<void> removeDocumentContext({
    required String userId,
    required String documentId,
  });
  Future<Map<String, dynamic>> getPrewarmedContext({required String userId});
}

class SupabaseDocumentContextPrewarmServiceImpl
    implements SupabaseDocumentContextPrewarmService {
  final SupabaseClient _supabase;

  SupabaseDocumentContextPrewarmServiceImpl({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<void> prewarmDocumentContext({
    required String userId,
    required VaultDocument document,
  }) async {
    try {
      // Store document context in separate collection like LinkedIn and Gmail
      final contextData = {
        'totalDocuments': 1,
        'recentDocuments': [
          {
            'id': document.id,
            'title': document.metadata.title.isNotEmpty
                ? document.metadata.title
                : document.originalName,
            'summary': document.content.summary,
            'uploadDate': document.uploadDate.toIso8601String(),
            'fileType': document.fileType,
            'fileSize': document.fileSize,
          },
        ],
        'documentCategories': {
          document.metadata.category.isNotEmpty
                  ? document.metadata.category
                  : 'uncategorized':
              1,
        },
        'summary': document.content.summary.isNotEmpty
            ? document.content.summary
            : 'Document uploaded: ${document.originalName}',
        'keywords': document.content.keywords.isNotEmpty
            ? document.content.keywords
            : [document.fileType],
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Store in separate collection like other contexts
      await _supabase.from('pda_context').upsert({
        'user_id': userId,
        'context_type': 'vault',
        'context': contextData,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error prewarming document context: $e');
    }
  }

  @override
  Future<void> removeDocumentContext({
    required String userId,
    required String documentId,
  }) async {
    try {
      // Simply delete the vault context when a document is removed
      // The context will be rebuilt when new documents are uploaded
      await _supabase
          .from('pda_context')
          .delete()
          .eq('user_id', userId)
          .eq('context_type', 'vault');
    } catch (e) {
      throw Exception('Error removing document context: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPrewarmedContext({
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('pda_context')
          .select()
          .eq('user_id', userId)
          .eq('context_type', 'vault')
          .maybeSingle();

      if (response != null) {
        return response['context'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      throw Exception('Error getting prewarmed context: $e');
    }
  }
}
