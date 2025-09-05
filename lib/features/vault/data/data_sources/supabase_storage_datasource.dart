import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<String> uploadFile({
    required String userId,
    required File file,
    required String filename,
  }) async {
    try {
      // Create the file path in Supabase Storage
      final filePath = 'vault/$userId/$filename';

      // Upload the file to Supabase Storage
      await _supabase.storage
          .from('vault-files')
          .uploadBinary(filePath, await file.readAsBytes());

      // Get the public URL for the uploaded file
      final publicUrl = _supabase.storage
          .from('vault-files')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Supabase Storage Error: $e');
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
