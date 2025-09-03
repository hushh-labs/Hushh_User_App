import '../repositories/gmail_repository.dart';

class SyncGmailUseCase {
  final GmailRepository repository;

  SyncGmailUseCase(this.repository);

  Future<SyncResult> call(String userId, SyncOptions syncOptions) async {
    try {
      final success = await repository.syncEmails(userId, syncOptions);

      if (success) {
        // Update sync settings for future use
        await repository.updateSyncSettings(userId, syncOptions);

        // Get updated email count
        final emailCount = await repository.getEmailCount(userId);

        return SyncResult.success(emailCount);
      } else {
        return SyncResult.failure('Sync operation failed');
      }
    } catch (e) {
      return SyncResult.failure('Failed to sync Gmail: $e');
    }
  }

  Future<SyncResult> syncNewEmails(String userId) async {
    try {
      final success = await repository.syncNewEmails(userId);

      if (success) {
        final emailCount = await repository.getEmailCount(userId);
        return SyncResult.success(emailCount);
      } else {
        return SyncResult.failure('New email sync failed');
      }
    } catch (e) {
      return SyncResult.failure('Failed to sync new emails: $e');
    }
  }
}

class SyncResult {
  final bool isSuccess;
  final String? error;
  final int? emailCount;

  const SyncResult._({required this.isSuccess, this.error, this.emailCount});

  factory SyncResult.success(int emailCount) {
    return SyncResult._(isSuccess: true, emailCount: emailCount);
  }

  factory SyncResult.failure(String error) {
    return SyncResult._(isSuccess: false, error: error);
  }
}
