import '../entities/drive_file.dart';

abstract class GoogleDriveRepository {
  // Connection management
  Future<bool> isGoogleDriveConnected(String userId);
  Future<bool> connectGoogleDriveAccount({
    required String userId,
    required String authCode,
  });
  Future<void> disconnectGoogleDrive(String userId);

  // Sync
  Future<void> triggerDriveSync(String userId);

  // Fetch cached files metadata
  Future<List<DriveFile>> getDriveFiles(String userId);
}
