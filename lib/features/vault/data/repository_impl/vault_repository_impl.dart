import 'dart:io';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';
import 'package:hushh_user_app/features/vault/data/data_sources/supabase_storage_datasource.dart';
import 'package:hushh_user_app/features/vault/data/data_sources/supabase_vault_datasource.dart';
import 'package:hushh_user_app/features/vault/data/models/vault_document_model.dart';
import 'package:hushh_user_app/features/vault/data/models/document_metadata_model.dart';
import 'package:hushh_user_app/features/vault/data/services/supabase_document_context_prewarm_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class VaultRepositoryImpl implements VaultRepository {
  final SupabaseStorageDataSource _supabaseStorageDataSource;
  final SupabaseVaultDataSource _supabaseVaultDataSource;
  final SupabaseDocumentContextPrewarmService _documentPrewarmService;
  final Uuid _uuid;

  VaultRepositoryImpl({
    required SupabaseStorageDataSource supabaseStorageDataSource,
    required SupabaseVaultDataSource supabaseVaultDataSource,
    required SupabaseDocumentContextPrewarmService documentPrewarmService,
    Uuid? uuid,
  }) : _supabaseStorageDataSource = supabaseStorageDataSource,
       _supabaseVaultDataSource = supabaseVaultDataSource,
       _documentPrewarmService = documentPrewarmService,
       _uuid = uuid ?? const Uuid();

  @override
  Future<VaultDocument> uploadDocument({
    required String userId,
    required File file,
    required String filename,
  }) async {
    try {
      final documentId = _uuid.v4();
      final downloadUrl = await _supabaseStorageDataSource.uploadFile(
        userId: userId,
        file: file,
        filename: filename,
      );

      final documentModel = VaultDocumentModel(
        id: documentId,
        userId: userId,
        filename: downloadUrl, // Store the Supabase download URL
        originalName: filename,
        fileType: filename.split('.').last,
        fileSize: await file.length(),
        uploadDate: DateTime.now(),
        lastModified: DateTime.now(),
        metadata: DocumentMetadataModel(
          title: '',
          description: '',
          tags: [],
          category: '',
        ),
        content: DocumentContentModel(
          extractedText: '',
          summary: '',
          keywords: [],
          wordCount: 0,
        ),
        isProcessed: false,
        isActive: true,
      );

      await _supabaseVaultDataSource.uploadDocumentMetadata(
        userId: userId,
        document: documentModel,
      );

      // Prewarm PDA context with the new document
      try {
        debugPrint(
          '🧠 [VAULT] Prewarming PDA context with new document: ${documentModel.originalName}',
        );
        await _documentPrewarmService.prewarmDocumentContext(
          userId: userId,
          document: documentModel,
        );
        debugPrint(
          '🧠 [VAULT] ✅ PDA context prewarming completed for document: ${documentModel.originalName}',
        );
      } catch (e) {
        debugPrint('⚠️ [VAULT] Failed to prewarm PDA context for document: $e');
        // Don't throw error here as the document upload was successful
        // PDA context prewarming is a secondary operation
      }

      return documentModel;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  @override
  Future<void> deleteDocument({
    required String userId,
    required String documentId,
  }) async {
    try {
      final document = await _supabaseVaultDataSource.getDocumentMetadata(
        userId: userId,
        documentId: documentId,
      );
      await _supabaseStorageDataSource.deleteFile(filePath: document.filename);
      await _supabaseVaultDataSource.deleteDocumentMetadata(
        userId: userId,
        documentId: documentId,
      );

      // Remove document from PDA context
      try {
        debugPrint(
          '🧠 [VAULT] Removing document from PDA context: $documentId',
        );
        await _documentPrewarmService.removeDocumentContext(
          userId: userId,
          documentId: documentId,
        );
        debugPrint(
          '🧠 [VAULT] ✅ Document removed from PDA context: $documentId',
        );
      } catch (e) {
        debugPrint('⚠️ [VAULT] Failed to remove document from PDA context: $e');
        // Don't throw error here as the document deletion was successful
      }
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  @override
  Future<List<VaultDocument>> getDocuments({required String userId}) async {
    try {
      return await _supabaseVaultDataSource.getDocumentsMetadata(
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to get documents: $e');
    }
  }

  @override
  Future<VaultDocument> extractDocumentContent({required String documentId}) {
    // TODO: Implement document content extraction logic
    throw UnimplementedError();
  }

  @override
  Future<void> clearAllDocuments(String userId) async {
    try {
      // Get all documents for the user first
      final documents = await _supabaseVaultDataSource.getDocumentsMetadata(
        userId: userId,
      );

      // Delete all files from storage
      for (final document in documents) {
        try {
          await _supabaseStorageDataSource.deleteFile(
            filePath: document.filename,
          );
        } catch (e) {
          debugPrint(
            '⚠️ [VAULT] Failed to delete file from storage: ${document.filename}, error: $e',
          );
          // Continue with other files even if one fails
        }
      }

      // Delete all document metadata from database
      await _supabaseVaultDataSource.clearAllDocumentsMetadata(userId);

      // Clear PDA context
      try {
        debugPrint('🧠 [VAULT] Clearing all PDA context for user: $userId');
        await _documentPrewarmService.clearAllDocumentContext(userId);
        debugPrint('🧠 [VAULT] ✅ All PDA context cleared for user: $userId');
      } catch (e) {
        debugPrint('⚠️ [VAULT] Failed to clear PDA context: $e');
        // Don't throw error here as the document clearing was successful
      }
    } catch (e) {
      throw Exception('Failed to clear all documents: $e');
    }
  }
}
