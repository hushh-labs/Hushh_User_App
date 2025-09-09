import 'package:flutter/foundation.dart';
import '../../domain/repositories/google_drive_repository.dart';
import '../../domain/entities/drive_file.dart';
import '../data_sources/google_drive_supabase_data_source.dart';
import '../models/drive_file_model.dart';

class GoogleDriveRepositoryImpl implements GoogleDriveRepository {
  final GoogleDriveSupabaseDataSource _dataSource;

  GoogleDriveRepositoryImpl({required GoogleDriveSupabaseDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<bool> isGoogleDriveConnected(String userId) {
    return _dataSource.isGoogleDriveConnected(userId);
  }

  @override
  Future<bool> connectGoogleDriveAccount({
    required String userId,
    required String authCode,
  }) async {
    try {
      final success = await _dataSource.completeGoogleDriveOAuth(
        userId,
        authCode,
      );
      if (success) {
        try {
          await triggerDriveSync(userId);
        } catch (e) {
          debugPrint('⚠️ [GOOGLE DRIVE] Auto-sync after OAuth failed: $e');
        }
      }
      return success;
    } catch (e) {
      debugPrint('❌ [GOOGLE DRIVE] Error connecting account: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnectGoogleDrive(String userId) {
    return _dataSource.disconnectGoogleDrive(userId);
  }

  @override
  Future<void> triggerDriveSync(String userId) async {
    final result = await _dataSource.triggerDriveSync(userId);
    if (result['success'] != true) {
      throw Exception('Drive sync failed: ${result['message']}');
    }
  }

  @override
  Future<List<DriveFile>> getDriveFiles(String userId) async {
    final models = await _dataSource.getDriveFiles(userId);
    return models.map((m) => m.toEntity()).toList();
  }
}
