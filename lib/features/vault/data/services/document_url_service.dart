import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service to generate secure URLs for document access by PDA/Claude
class DocumentUrlService {
  final SupabaseClient _supabase;

  DocumentUrlService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Generate a signed URL for document access
  /// This creates a temporary URL that Claude can use to access the document
  Future<String?> generateDocumentUrl({
    required String userId,
    required String filename,
    int expiresInSeconds = 3600, // 1 hour default
  }) async {
    try {
      // Extract the file path from the full URL if needed
      String filePath = filename;
      String bucketName = 'vault';

      if (filename.contains('/storage/v1/object/')) {
        // Extract the bucket name and file path from the full URL
        final uri = Uri.parse(filename);
        final pathSegments = uri.pathSegments;

        // Find the bucket name (should be after 'public' or 'sign')
        int bucketIndex = -1;
        for (int i = 0; i < pathSegments.length; i++) {
          if (pathSegments[i] == 'public' || pathSegments[i] == 'sign') {
            if (i + 1 < pathSegments.length) {
              bucketName = pathSegments[i + 1];
              bucketIndex = i + 1;
              break;
            }
          }
        }

        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          // Get the file path after the bucket name
          filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        } else {
          // Fallback: try to extract from the URL pattern
          final urlPattern = RegExp(r'/storage/v1/object/[^/]+/([^/]+)/(.+)');
          final match = urlPattern.firstMatch(filename);
          if (match != null) {
            bucketName = match.group(1) ?? 'vault';
            filePath = match.group(2) ?? filename;
          }
        }
      } else if (!filePath.contains('/')) {
        // If it's just a filename, prepend the user path
        filePath = '$userId/$filename';
      }

      debugPrint(
        '🔗 [DOCUMENT URL] Generating signed URL for bucket: $bucketName, path: $filePath',
      );

      // Generate signed URL for the document
      final signedUrl = await _supabase.storage
          .from(bucketName)
          .createSignedUrl(filePath, expiresInSeconds);

      debugPrint('🔗 [DOCUMENT URL] ✅ Generated signed URL successfully');
      return signedUrl;
    } catch (e) {
      debugPrint('❌ [DOCUMENT URL] Error generating signed URL: $e');
      // If signed URL fails, try to return the original URL if it's already public
      if (filename.contains('/storage/v1/object/public/')) {
        debugPrint('🔗 [DOCUMENT URL] Falling back to public URL: $filename');
        return filename;
      }
      return null;
    }
  }

  /// Generate signed URLs for multiple documents
  Future<Map<String, String>> generateMultipleDocumentUrls({
    required String userId,
    required List<String> filenames,
    int expiresInSeconds = 3600,
  }) async {
    final Map<String, String> urls = {};

    for (final filename in filenames) {
      final url = await generateDocumentUrl(
        userId: userId,
        filename: filename,
        expiresInSeconds: expiresInSeconds,
      );
      if (url != null) {
        urls[filename] = url;
      }
    }

    return urls;
  }

  /// Check if a file exists in storage
  Future<bool> documentExists({
    required String userId,
    required String filename,
  }) async {
    try {
      String filePath = filename;
      if (filename.contains('/storage/v1/object/')) {
        final uri = Uri.parse(filename);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('vault');
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        }
      }

      final response = await _supabase.storage
          .from('vault')
          .list(
            path: filePath
                .split('/')
                .sublist(0, filePath.split('/').length - 1)
                .join('/'),
          );

      final fileName = filePath.split('/').last;
      return response.any((file) => file.name == fileName);
    } catch (e) {
      debugPrint('❌ [DOCUMENT URL] Error checking document existence: $e');
      return false;
    }
  }

  /// Generate public URL (if bucket is configured for public access)
  /// Note: This should only be used if the vault bucket is configured for public access
  String? generatePublicUrl({
    required String userId,
    required String filename,
  }) {
    try {
      String filePath = filename;
      if (filename.contains('/storage/v1/object/')) {
        final uri = Uri.parse(filename);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('vault');
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        }
      }

      final publicUrl = _supabase.storage.from('vault').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ [DOCUMENT URL] Error generating public URL: $e');
      return null;
    }
  }
}
