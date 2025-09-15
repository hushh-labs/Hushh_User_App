import '../entities/gmail_account.dart';
import '../entities/gmail_email.dart';

enum SyncDuration {
  oneWeek(7, '1 Week'),
  // fifteenDays(15, '15 Days'),
  // oneMonth(30, '1 Month'),
  custom(0, 'Custom');

  const SyncDuration(this.days, this.displayName);
  final int days;
  final String displayName;
}

class SyncOptions {
  final SyncDuration duration;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const SyncOptions({
    required this.duration,
    this.customStartDate,
    this.customEndDate,
  });

  DateTime get startDate {
    if (duration == SyncDuration.custom && customStartDate != null) {
      return customStartDate!;
    }
    return DateTime.now().subtract(Duration(days: duration.days));
  }

  DateTime get endDate {
    if (duration == SyncDuration.custom && customEndDate != null) {
      return customEndDate!;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration.name,
      'durationDays': duration.days,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
    };
  }

  factory SyncOptions.fromJson(Map<String, dynamic> json) {
    final durationName = json['duration'] as String?;
    final duration = SyncDuration.values.firstWhere(
      (d) => d.name == durationName,
      orElse: () => SyncDuration.oneWeek,
    );

    return SyncOptions(
      duration: duration,
      customStartDate: json['customStartDate'] != null
          ? DateTime.parse(json['customStartDate'])
          : null,
      customEndDate: json['customEndDate'] != null
          ? DateTime.parse(json['customEndDate'])
          : null,
    );
  }
}

abstract class GmailRepository {
  // Account Management
  Future<bool> connectGmail(
    String userId, {
    required String accessToken,
    String? refreshToken,
    String? idToken,
    required String email,
    required List<String> scopes,
  });

  Future<bool> disconnectGmail(String userId);
  Future<bool> isGmailConnected(String userId);
  Future<GmailAccount?> getGmailAccount(String userId);

  // Email Sync
  Future<bool> syncEmails(String userId, SyncOptions syncOptions);
  Future<bool> syncNewEmails(String userId);
  Future<List<GmailEmail>> getEmails(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  });

  // Sync Settings
  Future<bool> updateSyncSettings(String userId, SyncOptions syncOptions);
  Future<SyncOptions?> getSyncSettings(String userId);
  Future<DateTime?> getLastSyncDate(String userId);

  // Email Management
  Future<int> getEmailCount(String userId);
  Future<bool> deleteOldEmails(String userId, DateTime beforeDate);

  // Stream for real-time updates
  Stream<bool> get connectionStatusStream;
  Stream<List<GmailEmail>> getEmailsStream(String userId);
}
