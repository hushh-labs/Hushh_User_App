import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hushh_user_app/core/config/supabase_init.dart';
import 'package:hushh_user_app/features/vault/data/models/vault_document_model.dart';
import 'package:hushh_user_app/features/vault/data/models/document_metadata_model.dart';

abstract class SupabaseVaultDataSource {
  Future<VaultDocumentModel> uploadDocumentMetadata({
    required String userId,
    required VaultDocumentModel document,
  });
  Future<void> deleteDocumentMetadata({
    required String userId,
    required String documentId,
  });
  Future<List<VaultDocumentModel>> getDocumentsMetadata({
    required String userId,
  });
  Future<VaultDocumentModel> getDocumentMetadata({
    required String userId,
    required String documentId,
  });
  Future<void> updateDocumentMetadata({
    required String userId,
    required VaultDocumentModel document,
  });
  Future<void> clearAllDocumentsMetadata(String userId);
}

class SupabaseVaultDataSourceImpl implements SupabaseVaultDataSource {
  final SupabaseClient _supabase;

  SupabaseVaultDataSourceImpl({SupabaseClient? supabase})
    : _supabase =
          supabase ?? (SupabaseInit.serviceClient ?? Supabase.instance.client);

  @override
  Future<VaultDocumentModel> uploadDocumentMetadata({
    required String userId,
    required VaultDocumentModel document,
  }) async {
    try {
      final response = await _supabase
          .from('vault_documents')
          .insert({
            'id': document.id,
            'user_id': userId,
            'filename': document.filename,
            'original_name': document.originalName,
            'file_type': document.fileType,
            'file_size': document.fileSize,
            'upload_date': document.uploadDate.toIso8601String(),
            'last_modified': document.lastModified.toIso8601String(),
            'metadata': {
              'title': document.metadata.title,
              'description': document.metadata.description,
              'tags': document.metadata.tags,
              'category': document.metadata.category,
            },
            'content': {
              'extracted_text': document.content.extractedText,
              'summary': document.content.summary,
              'keywords': document.content.keywords,
              'word_count': document.content.wordCount,
            },
            'is_processed': document.isProcessed,
            'is_active': document.isActive,
          })
          .select()
          .single();

      return _mapResponseToModel(response);
    } catch (e) {
      throw Exception('Supabase Error: $e');
    }
  }

  @override
  Future<void> deleteDocumentMetadata({
    required String userId,
    required String documentId,
  }) async {
    try {
      await _supabase
          .from('vault_documents')
          .delete()
          .eq('id', documentId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Supabase Error: $e');
    }
  }

  @override
  Future<List<VaultDocumentModel>> getDocumentsMetadata({
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('vault_documents')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('upload_date', ascending: false);

      return (response as List).map((doc) => _mapResponseToModel(doc)).toList();
    } catch (e) {
      throw Exception('Supabase Error: $e');
    }
  }

  @override
  Future<VaultDocumentModel> getDocumentMetadata({
    required String userId,
    required String documentId,
  }) async {
    try {
      final response = await _supabase
          .from('vault_documents')
          .select()
          .eq('id', documentId)
          .eq('user_id', userId)
          .single();

      return _mapResponseToModel(response);
    } catch (e) {
      throw Exception('Supabase Error: $e');
    }
  }

  @override
  Future<void> updateDocumentMetadata({
    required String userId,
    required VaultDocumentModel document,
  }) async {
    try {
      await _supabase
          .from('vault_documents')
          .update({
            'filename': document.filename,
            'original_name': document.originalName,
            'file_type': document.fileType,
            'file_size': document.fileSize,
            'last_modified': document.lastModified.toIso8601String(),
            'metadata': {
              'title': document.metadata.title,
              'description': document.metadata.description,
              'tags': document.metadata.tags,
              'category': document.metadata.category,
            },
            'content': {
              'extracted_text': document.content.extractedText,
              'summary': document.content.summary,
              'keywords': document.content.keywords,
              'word_count': document.content.wordCount,
            },
            'is_processed': document.isProcessed,
            'is_active': document.isActive,
          })
          .eq('id', document.id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Supabase Error: $e');
    }
  }

  @override
  Future<void> clearAllDocumentsMetadata(String userId) async {
    try {
      await _supabase.from('vault_documents').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Supabase Error: $e');
    }
  }

  /// Map Supabase response to VaultDocumentModel
  VaultDocumentModel _mapResponseToModel(Map<String, dynamic> response) {
    return VaultDocumentModel(
      id: response['id'] as String,
      userId: response['user_id'] as String,
      filename: response['filename'] as String,
      originalName: response['original_name'] as String,
      fileType: response['file_type'] as String,
      fileSize: response['file_size'] as int,
      uploadDate: DateTime.parse(response['upload_date'] as String),
      lastModified: DateTime.parse(response['last_modified'] as String),
      metadata: DocumentMetadataModel(
        title: response['metadata']['title'] as String? ?? '',
        description: response['metadata']['description'] as String? ?? '',
        tags: List<String>.from(response['metadata']['tags'] ?? []),
        category: response['metadata']['category'] as String? ?? '',
      ),
      content: DocumentContentModel(
        extractedText: response['content']['extracted_text'] as String? ?? '',
        summary: response['content']['summary'] as String? ?? '',
        keywords: List<String>.from(response['content']['keywords'] ?? []),
        wordCount: response['content']['word_count'] as int? ?? 0,
      ),
      isProcessed: response['is_processed'] as bool? ?? false,
      isActive: response['is_active'] as bool? ?? true,
    );
  }
}
