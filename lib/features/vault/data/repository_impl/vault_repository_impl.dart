import 'dart:io';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';
import 'package:hushh_user_app/features/vault/data/data_sources/supabase_storage_datasource.dart';
import 'package:hushh_user_app/features/vault/data/data_sources/supabase_vault_datasource.dart';
import 'package:hushh_user_app/features/vault/data/models/vault_document_model.dart';
import 'package:hushh_user_app/features/vault/data/models/document_metadata_model.dart';
import 'package:uuid/uuid.dart';

class VaultRepositoryImpl implements VaultRepository {
  final SupabaseStorageDataSource _supabaseStorageDataSource;
  final SupabaseVaultDataSource _supabaseVaultDataSource;
  final Uuid _uuid;

  VaultRepositoryImpl({
    required SupabaseStorageDataSource supabaseStorageDataSource,
    required SupabaseVaultDataSource supabaseVaultDataSource,
    Uuid? uuid,
  }) : _supabaseStorageDataSource = supabaseStorageDataSource,
       _supabaseVaultDataSource = supabaseVaultDataSource,
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
}
