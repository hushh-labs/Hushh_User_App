import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hushh_user_app/core/config/supabase_init.dart';
import 'google_drive_supabase_data_source.dart';
import '../models/drive_file_model.dart';

class OAuthUrlException implements Exception {
  final String authUrl;
  const OAuthUrlException(this.authUrl);
  @override
  String toString() => 'OAuthUrlException: $authUrl';
}

class GoogleDriveSupabaseDataSourceImpl
    implements GoogleDriveSupabaseDataSource {
  final SupabaseClient _supabase;
  GoogleDriveSupabaseDataSourceImpl({SupabaseClient? supabase})
    : _supabase =
          supabase ?? (SupabaseInit.serviceClient ?? Supabase.instance.client);

  @override
  Future<bool> isGoogleDriveConnected(String userId) async {
    try {
      final response = await _supabase
          .from('google_drive_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('❌ [GOOGLE DRIVE] Error checking connection: $e');
      return false;
    }
  }

  @override
  Future<void> initiateGoogleDriveOAuth(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'google-drive-sync',
        body: {'userId': userId, 'action': 'connect'},
      );
      final authUrl = response.data?['authUrl'] as String?;
      if (response.data?['success'] == true && authUrl != null) {
        throw OAuthUrlException(authUrl);
      }
      throw Exception('Failed to initiate Drive OAuth: ${response.data}');
    } catch (e) {
      if (e is OAuthUrlException) rethrow;
      debugPrint('❌ [GOOGLE DRIVE] Error initiating OAuth: $e');
      throw Exception('Failed to initiate Google Drive OAuth: $e');
    }
  }

  @override
  Future<bool> completeGoogleDriveOAuth(String userId, String authCode) async {
    try {
      final response = await _supabase.functions.invoke(
        'google-drive-sync',
        body: {'userId': userId, 'action': 'callback', 'code': authCode},
      );
      return response.data?['success'] == true;
    } catch (e) {
      debugPrint('❌ [GOOGLE DRIVE] Error completing OAuth: $e');
      throw Exception('Failed to complete Google Drive OAuth: $e');
    }
  }

  @override
  Future<void> disconnectGoogleDrive(String userId) async {
    try {
      await _supabase
          .from('google_drive_accounts')
          .update({'is_active': false})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('❌ [GOOGLE DRIVE] Error disconnecting: $e');
      throw Exception('Failed to disconnect Google Drive: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> triggerDriveSync(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'google-drive-sync',
        body: {'userId': userId, 'action': 'sync'},
      );
      if (response.data?['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Drive sync started',
          'syncedAt': DateTime.now().toIso8601String(),
        };
      }
      throw Exception('Failed to trigger Drive sync: ${response.data}');
    } catch (e) {
      debugPrint('❌ [GOOGLE DRIVE] Error triggering sync: $e');
      throw Exception('Failed to trigger Drive sync: $e');
    }
  }

  @override
  Future<List<DriveFileModel>> getDriveFiles(String userId) async {
    try {
      final rows = await _supabase
          .from('DriveFile')
          .select()
          .eq('user_id', userId)
          .order('modified_time', ascending: false);
      return rows
          .map<DriveFileModel>(
            (json) => DriveFileModel(
              id: json['id'] as String,
              fileId: json['file_id'] as String,
              userUid: json['user_id'] as String,
              name: json['name'] as String?,
              mimeType: json['mime_type'] as String?,
              size: (json['size'] as int?)?.toInt(),
              createdTime: json['created_time'] != null
                  ? DateTime.parse(json['created_time'] as String)
                  : null,
              modifiedTime: json['modified_time'] != null
                  ? DateTime.parse(json['modified_time'] as String)
                  : null,
              shared: json['shared'] as bool?,
              webViewLink: json['web_view_link'] as String?,
              thumbnailLink: json['thumbnail_link'] as String?,
              trashed: (json['trashed'] as bool?) ?? false,
              insertedAt: json['inserted_at'] != null
                  ? DateTime.parse(json['inserted_at'] as String)
                  : null,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ [GOOGLE DRIVE] Error fetching Drive files: $e');
      return [];
    }
  }
}
