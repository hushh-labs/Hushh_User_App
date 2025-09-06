import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:hushh_user_app/features/vault/domain/entities/document_metadata.dart';
import 'package:hushh_user_app/features/vault/data/services/document_url_service.dart';
import 'package:hushh_user_app/features/vault/data/services/local_file_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';

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
  final DocumentUrlService _urlService;
  final LocalFileCacheService _cacheService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SupabaseDocumentContextPrewarmServiceImpl({
    SupabaseClient? supabase,
    DocumentUrlService? urlService,
    LocalFileCacheService? cacheService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _urlService = urlService ?? DocumentUrlService(),
       _cacheService = cacheService ?? LocalFileCacheService(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> prewarmDocumentContext({
    required String userId,
    required VaultDocument document,
  }) async {
    try {
      // Get existing context to merge with new document
      final existingContext = await getPrewarmedContext(userId: userId);

      // Get all user documents to build comprehensive context
      final allDocuments = await _getAllUserDocuments(userId);

      // Build comprehensive context from all documents
      final contextData = await _buildComprehensiveContext(allDocuments);

      // Store in Firebase Firestore like other PDA contexts (Gmail, LinkedIn)
      debugPrint(
        '🔍 [VAULT SAVE] Attempting to save context with ${contextData['totalDocuments']} documents',
      );

      try {
        await _firestore
            .collection('HushUsers')
            .doc(userId)
            .collection('pda_context')
            .doc('vault')
            .set({
              'context': contextData,
              'lastUpdated': FieldValue.serverTimestamp(),
              'version': '1.0',
            });
        debugPrint('🔍 [VAULT SAVE] ✅ Context saved successfully');
      } catch (e) {
        debugPrint('❌ [VAULT SAVE] Failed to save context: $e');
        debugPrint(
          '❌ [VAULT SAVE] Context data keys: ${contextData.keys.toList()}',
        );
        debugPrint(
          '❌ [VAULT SAVE] Total documents: ${contextData['totalDocuments']}',
        );
        debugPrint(
          '❌ [VAULT SAVE] Recent documents count: ${(contextData['recentDocuments'] as List?)?.length ?? 0}',
        );
        throw e;
      }
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
      // Get the document to be removed to find its original name for cache cleanup
      final allDocuments = await _getAllUserDocuments(userId);
      final documentToRemove = allDocuments.firstWhere(
        (doc) => doc.id == documentId,
        orElse: () => throw Exception('Document not found'),
      );

      // Remove from local cache
      await _cacheService.initialize();
      await _cacheService.removeCachedFileData(
        userId: userId,
        fileName: documentToRemove.originalName,
      );
      debugPrint(
        '🗑️ [VAULT CACHE] Removed cached file data for ${documentToRemove.originalName}',
      );

      // Get remaining documents after deletion and rebuild context
      final remainingDocuments = await _getAllUserDocuments(userId);
      final filteredDocuments = remainingDocuments
          .where((doc) => doc.id != documentId)
          .toList();

      if (filteredDocuments.isEmpty) {
        // No documents left, delete the context and clear all cache
        await _firestore
            .collection('HushUsers')
            .doc(userId)
            .collection('pda_context')
            .doc('vault')
            .delete();

        await _cacheService.clearUserCache(userId);
        debugPrint('🗑️ [VAULT CACHE] Cleared all cached files for user');
      } else {
        // Rebuild context with remaining documents
        final contextData = await _buildComprehensiveContext(filteredDocuments);
        await _firestore
            .collection('HushUsers')
            .doc(userId)
            .collection('pda_context')
            .doc('vault')
            .set({
              'context': contextData,
              'lastUpdated': FieldValue.serverTimestamp(),
              'version': '1.0',
            });
      }
    } catch (e) {
      throw Exception('Error removing document context: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPrewarmedContext({
    required String userId,
  }) async {
    try {
      debugPrint(
        '🔍 [VAULT CACHE] Getting prewarmed context for user: $userId',
      );

      final doc = await _firestore
          .collection('HushUsers')
          .doc(userId)
          .collection('pda_context')
          .doc('vault')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final context = data['context'] as Map<String, dynamic>? ?? {};

        final totalDocs = context['totalDocuments'] ?? 0;
        final recentDocs = context['recentDocuments'] as List<dynamic>? ?? [];

        debugPrint(
          '🔍 [VAULT CACHE] Found cached context with $totalDocs total documents',
        );
        debugPrint(
          '🔍 [VAULT CACHE] Recent documents count: ${recentDocs.length}',
        );

        for (int i = 0; i < recentDocs.length; i++) {
          final doc = recentDocs[i];
          debugPrint(
            '🔍 [VAULT CACHE] Cached document $i: ${doc['originalName']} (hasFileData: ${doc['hasFileData']})',
          );
        }

        return context;
      } else {
        debugPrint(
          '🔍 [VAULT CACHE] No cached context found, will query database',
        );
        return {};
      }
    } catch (e) {
      debugPrint('❌ [VAULT CACHE] Error getting prewarmed context: $e');
      throw Exception('Error getting prewarmed context: $e');
    }
  }

  /// Get all user documents from vault_documents table
  Future<List<VaultDocument>> _getAllUserDocuments(String userId) async {
    try {
      debugPrint('🔍 [VAULT QUERY] Querying documents for user: $userId');

      final response = await _supabase
          .from('vault_documents')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('upload_date', ascending: false);

      debugPrint('🔍 [VAULT QUERY] Raw response: $response');
      debugPrint('🔍 [VAULT QUERY] Found ${response.length} documents');

      for (int i = 0; i < response.length; i++) {
        final doc = response[i];
        debugPrint(
          '🔍 [VAULT QUERY] Document $i: ${doc['original_name']} (ID: ${doc['id']}, Active: ${doc['is_active']})',
        );
      }

      return response.map<VaultDocument>((doc) {
        return VaultDocument(
          id: doc['id'] ?? '',
          userId: doc['user_id'] ?? '',
          filename: doc['filename'] ?? '',
          originalName: doc['original_name'] ?? '',
          fileType: doc['file_type'] ?? '',
          fileSize: doc['file_size'] ?? 0,
          uploadDate:
              DateTime.tryParse(doc['upload_date'] ?? '') ?? DateTime.now(),
          lastModified:
              DateTime.tryParse(doc['last_modified'] ?? '') ?? DateTime.now(),
          metadata: DocumentMetadata(
            title: doc['metadata']?['title'] ?? '',
            description: doc['metadata']?['description'] ?? '',
            tags: List<String>.from(doc['metadata']?['tags'] ?? []),
            category: doc['metadata']?['category'] ?? '',
          ),
          content: DocumentContent(
            extractedText: doc['content']?['extracted_text'] ?? '',
            summary: doc['content']?['summary'] ?? '',
            keywords: List<String>.from(doc['content']?['keywords'] ?? []),
            wordCount: doc['content']?['word_count'] ?? 0,
          ),
          isProcessed: doc['is_processed'] ?? false,
          isActive: doc['is_active'] ?? true,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error getting user documents: $e');
    }
  }

  /// Build comprehensive context from all user documents
  Future<Map<String, dynamic>> _buildComprehensiveContext(
    List<VaultDocument> documents,
  ) async {
    if (documents.isEmpty) {
      return {
        'totalDocuments': 0,
        'recentDocuments': [],
        'documentCategories': {},
        'summary': 'No documents available.',
        'keywords': [],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }

    // Sort documents by upload date (most recent first)
    final sortedDocuments = List<VaultDocument>.from(documents)
      ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

    // Get recent documents (last 10) with file URLs
    final recentDocumentsList = <Map<String, dynamic>>[];
    for (final doc in sortedDocuments.take(10)) {
      try {
        // Generate signed URL for Claude to access the document
        final fileUrl = await _urlService.generateDocumentUrl(
          userId: doc.userId,
          filename: doc.filename,
          expiresInSeconds: 7200, // 2 hours for PDA context
        );

        debugPrint(
          '🔗 [VAULT CONTEXT] Generated URL for ${doc.originalName}: ${fileUrl != null ? 'Success' : 'Failed'}',
        );

        final docData = {
          'id': doc.id,
          'title': doc.metadata.title.isNotEmpty
              ? doc.metadata.title
              : doc.originalName,
          'summary': doc.content.summary.isNotEmpty
              ? doc.content.summary
              : 'Document: ${doc.originalName}',
          'uploadDate': doc.uploadDate.toIso8601String(),
          'fileType': doc.fileType,
          'fileSize': doc.fileSize,
          'category': doc.metadata.category.isNotEmpty
              ? doc.metadata.category
              : 'uncategorized',
          'originalName': doc.originalName,
          'wordCount': doc.content.wordCount,
          'keywords': doc.content.keywords,
        };

        // Download and cache file data locally instead of storing in Firestore
        try {
          await _cacheService.initialize();
          final fileData = await _downloadAndEncodeFile(
            doc.userId,
            doc.filename,
            doc.fileType,
          );

          if (fileData != null) {
            // Cache the file data locally
            final cached = await _cacheService.cacheFileData(
              userId: doc.userId,
              fileName: doc.originalName,
              base64Data: fileData['base64'],
              mimeType: fileData['mimeType'],
            );

            if (cached) {
              docData['hasFileData'] = true;
              docData['accessibleToClaude'] = true;
              docData['mimeType'] = fileData['mimeType'];
              docData['cachedLocally'] = true;
              debugPrint(
                '💾 [VAULT CACHE] Cached file data locally for ${doc.originalName} (${fileData['size']} bytes)',
              );
            } else {
              docData['hasFileData'] = false;
              docData['accessibleToClaude'] = false;
              docData['cachedLocally'] = false;
              debugPrint(
                '❌ [VAULT CACHE] Failed to cache file data for ${doc.originalName}',
              );
            }
          } else {
            docData['hasFileData'] = false;
            docData['accessibleToClaude'] = false;
            docData['cachedLocally'] = false;
            debugPrint(
              '❌ [VAULT CACHE] Could not download file data for ${doc.originalName}',
            );
          }
        } catch (e) {
          debugPrint(
            '❌ [VAULT CACHE] Error caching file data for ${doc.originalName}: $e',
          );
          docData['hasFileData'] = false;
          docData['accessibleToClaude'] = false;
          docData['cachedLocally'] = false;
        }

        // Add file URL as backup
        if (fileUrl != null) {
          docData['fileUrl'] = fileUrl;
        }

        recentDocumentsList.add(docData);
      } catch (e) {
        debugPrint(
          '❌ [VAULT CONTEXT] Error generating URL for ${doc.originalName}: $e',
        );
        // Add document without URL if URL generation fails
        final fallbackDocData = {
          'id': doc.id,
          'title': doc.metadata.title.isNotEmpty
              ? doc.metadata.title
              : doc.originalName,
          'summary': doc.content.summary.isNotEmpty
              ? doc.content.summary
              : 'Document: ${doc.originalName}',
          'uploadDate': doc.uploadDate.toIso8601String(),
          'fileType': doc.fileType,
          'fileSize': doc.fileSize,
          'category': doc.metadata.category.isNotEmpty
              ? doc.metadata.category
              : 'uncategorized',
          'originalName': doc.originalName,
          'wordCount': doc.content.wordCount,
          'keywords': doc.content.keywords,
        };

        // Try to download and encode the actual file even without URL
        try {
          final fileData = await _downloadAndEncodeFile(
            doc.userId,
            doc.filename,
            doc.fileType,
          );
          if (fileData != null) {
            fallbackDocData['fileData'] = fileData['base64'];
            fallbackDocData['mimeType'] = fileData['mimeType'];
            fallbackDocData['hasFileData'] = true;
            fallbackDocData['accessibleToClaude'] = true;
            debugPrint(
              '📄 [VAULT CONTEXT] Including file data for ${doc.originalName}: ${fileData['size']} bytes',
            );
          } else {
            fallbackDocData['hasFileData'] = false;
            fallbackDocData['accessibleToClaude'] = false;
          }
        } catch (e) {
          debugPrint(
            '❌ [VAULT CONTEXT] Error downloading file data for ${doc.originalName}: $e',
          );
          fallbackDocData['hasFileData'] = false;
          fallbackDocData['accessibleToClaude'] = false;
        }

        recentDocumentsList.add(fallbackDocData);
      }
    }
    final recentDocuments = recentDocumentsList;

    // Aggregate document categories
    final Map<String, int> documentCategories = {};
    for (final doc in documents) {
      final category = doc.metadata.category.isNotEmpty
          ? doc.metadata.category
          : 'uncategorized';
      documentCategories[category] = (documentCategories[category] ?? 0) + 1;
    }

    // Aggregate all keywords
    final Set<String> allKeywords = {};
    for (final doc in documents) {
      allKeywords.addAll(doc.content.keywords);
      if (doc.fileType.isNotEmpty) {
        allKeywords.add(doc.fileType);
      }
    }

    // Create overall summary
    final totalDocs = documents.length;
    final processedDocs = documents.where((doc) => doc.isProcessed).length;
    final topCategories = documentCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String overallSummary =
        'User has $totalDocs document${totalDocs == 1 ? '' : 's'} in their vault';
    if (processedDocs > 0) {
      overallSummary += ', $processedDocs processed';
    }
    if (topCategories.isNotEmpty) {
      final topCategory = topCategories.first;
      overallSummary +=
          '. Most documents are in "${topCategory.key}" category (${topCategory.value} document${topCategory.value == 1 ? '' : 's'})';
    }
    overallSummary += '.';

    return {
      'totalDocuments': totalDocs,
      'processedDocuments': processedDocs,
      'recentDocuments': recentDocuments,
      'documentCategories': documentCategories,
      'summary': overallSummary,
      'keywords': allKeywords.toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Download and encode file as base64 for Claude
  Future<Map<String, dynamic>?> _downloadAndEncodeFile(
    String userId,
    String filename,
    String fileType,
  ) async {
    try {
      // Use the document URL service to get the proper signed URL first
      final signedUrl = await _urlService.generateDocumentUrl(
        userId: userId,
        filename: filename,
        expiresInSeconds: 3600, // 1 hour
      );

      if (signedUrl != null) {
        debugPrint('📥 [FILE DOWNLOAD] Downloading file: $signedUrl');

        // Extract bucket and path from the signed URL
        final uri = Uri.parse(signedUrl);
        final pathSegments = uri.pathSegments;

        String bucketName = 'vault-files'; // Default to vault-files
        String filePath = filename;

        // Find the bucket name in the URL path
        for (int i = 0; i < pathSegments.length; i++) {
          if (pathSegments[i] == 'public' || pathSegments[i] == 'sign') {
            if (i + 1 < pathSegments.length) {
              bucketName = pathSegments[i + 1];
              if (i + 2 < pathSegments.length) {
                filePath = pathSegments.sublist(i + 2).join('/');
              }
              break;
            }
          }
        }

        debugPrint(
          '📥 [FILE DOWNLOAD] Downloading from bucket: $bucketName, path: $filePath',
        );

        // Download the file from Supabase storage
        final Uint8List fileBytes = await _supabase.storage
            .from(bucketName)
            .download(filePath);

        // Encode to base64
        final String base64Data = base64Encode(fileBytes);

        // Determine MIME type based on file extension
        final String mimeType = _getMimeType(fileType);

        debugPrint(
          '✅ [FILE DOWNLOAD] Successfully downloaded and encoded ${fileBytes.length} bytes',
        );

        return {
          'base64': base64Data,
          'mimeType': mimeType,
          'size': fileBytes.length,
          'filename': filename,
        };
      } else {
        debugPrint(
          '❌ [FILE DOWNLOAD] Could not generate signed URL for: $filename',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [FILE DOWNLOAD] Error downloading file: $e');
      return null;
    }
  }

  /// Get MIME type based on file extension
  String _getMimeType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }
}
