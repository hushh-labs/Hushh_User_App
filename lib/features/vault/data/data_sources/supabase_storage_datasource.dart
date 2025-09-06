import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hushh_user_app/core/config/supabase_init.dart';

abstract class SupabaseStorageDataSource {
  Future<String> uploadFile({
    required String userId,
    required File file,
    required String filename,
  });
  Future<void> deleteFile({required String filePath});
  Future<String> getPublicUrl({required String filePath});
}

class SupabaseStorageDataSourceImpl implements SupabaseStorageDataSource {
  final SupabaseClient _supabase;

  SupabaseStorageDataSourceImpl({SupabaseClient? supabase})
    : _supabase =
          supabase ?? (SupabaseInit.serviceClient ?? Supabase.instance.client);

  @override
  Future<String> uploadFile({
    required String userId,
    required File file,
    required String filename,
  }) async {
    try {
      print('Storage: Starting upload for user: $userId, file: $filename');
      print(
        'Storage: Using service client: ${SupabaseInit.serviceClient != null}',
      );

      // First, ensure the bucket exists
      await _ensureBucketExists();

      // Create the file path in Supabase Storage
      // Use Firebase UID as the user identifier
      final filePath = 'vault/$userId/$filename';
      print('Storage: File path: $filePath');

      // Upload the file to Supabase Storage
      final result = await _supabase.storage
          .from('vault-files')
          .uploadBinary(filePath, await file.readAsBytes());

      print('Storage: Upload result: $result');

      // Get the public URL for the uploaded file
      final publicUrl = _supabase.storage
          .from('vault-files')
          .getPublicUrl(filePath);

      print('Storage: Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Storage: Upload failed: $e');
      throw Exception('Supabase Storage Error: $e');
    }
  }

  /// Ensure the vault-files bucket exists, create it if it doesn't
  Future<void> _ensureBucketExists() async {
    try {
      // Try to get the bucket, if it doesn't exist, create it
      await _supabase.storage.getBucket('vault-files');
    } catch (e) {
      // Bucket doesn't exist, create it
      await _supabase.storage.createBucket(
        'vault-files',
        BucketOptions(
          public: true,
          allowedMimeTypes: null, // Allow all file types
          fileSizeLimit: '50MB', // 50MB limit
        ),
      );
    }
  }

  @override
  Future<void> deleteFile({required String filePath}) async {
    try {
      // Extract the file path from the public URL
      final path = _extractPathFromUrl(filePath);

      // Delete the file from Supabase Storage
      await _supabase.storage.from('vault-files').remove([path]);
    } catch (e) {
      throw Exception('Supabase Storage Error: $e');
    }
  }

  @override
  Future<String> getPublicUrl({required String filePath}) async {
    try {
      return _supabase.storage.from('vault-files').getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Supabase Storage Error: $e');
    }
  }

  /// Extract the file path from a Supabase Storage public URL
  String _extractPathFromUrl(String url) {
    // Supabase Storage URLs typically look like:
    // https://[project].supabase.co/storage/v1/object/public/vault-files/vault/user123/file.pdf
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    // Find the index of 'vault-files' and get everything after it
    final vaultFilesIndex = pathSegments.indexOf('vault-files');
    if (vaultFilesIndex != -1 && vaultFilesIndex + 1 < pathSegments.length) {
      return pathSegments.sublist(vaultFilesIndex + 1).join('/');
    }

    // Fallback: assume the URL contains the path after the last '/'
    return url.split('/').last;
  }
}
