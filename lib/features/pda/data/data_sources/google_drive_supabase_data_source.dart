import '../models/drive_file_model.dart';

abstract class GoogleDriveSupabaseDataSource {
  // Account operations
  Future<bool> isGoogleDriveConnected(String userId);
  Future<void> disconnectGoogleDrive(String userId);
  Future<void> initiateGoogleDriveOAuth(String userId);
  Future<bool> completeGoogleDriveOAuth(String userId, String authCode);

  // Sync trigger
  Future<Map<String, dynamic>> triggerDriveSync(String userId);

  // Cached file metadata
  Future<List<DriveFileModel>> getDriveFiles(String userId);
}
