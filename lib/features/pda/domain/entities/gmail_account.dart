import 'package:equatable/equatable.dart';

class GmailAccount extends Equatable {
  final String userId;
  final bool isConnected;
  final String? email;
  final String provider;
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final List<String>? scopes;
  final String? historyId;
  final DateTime? lastSyncAt;
  final Map<String, dynamic>? syncSettings;
  final DateTime? connectedAt;

  const GmailAccount({
    required this.userId,
    required this.isConnected,
    this.email,
    this.provider = 'gmail',
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.scopes,
    this.historyId,
    this.lastSyncAt,
    this.syncSettings,
    this.connectedAt,
  });

  @override
  List<Object?> get props => [
    userId,
    isConnected,
    email,
    provider,
    accessToken,
    refreshToken,
    idToken,
    scopes,
    historyId,
    lastSyncAt,
    syncSettings,
    connectedAt,
  ];

  GmailAccount copyWith({
    String? userId,
    bool? isConnected,
    String? email,
    String? provider,
    String? accessToken,
    String? refreshToken,
    String? idToken,
    List<String>? scopes,
    String? historyId,
    DateTime? lastSyncAt,
    Map<String, dynamic>? syncSettings,
    DateTime? connectedAt,
  }) {
    return GmailAccount(
      userId: userId ?? this.userId,
      isConnected: isConnected ?? this.isConnected,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      idToken: idToken ?? this.idToken,
      scopes: scopes ?? this.scopes,
      historyId: historyId ?? this.historyId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncSettings: syncSettings ?? this.syncSettings,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  /// Check if the account has valid tokens for API access
  bool get hasValidTokens => accessToken != null || refreshToken != null;

  /// Get sync duration setting in days (default: 30 days)
  int get syncDurationDays {
    final settings = syncSettings;
    if (settings == null) return 30;

    return settings['durationDays'] as int? ?? 30;
  }

  /// Get sync start date based on duration setting
  DateTime get syncStartDate {
    final now = DateTime.now();
    return now.subtract(Duration(days: syncDurationDays));
  }

  /// Check if the account needs to be synced
  bool get needsSync {
    if (!isConnected || !hasValidTokens) return false;
    if (lastSyncAt == null) return true;

    // Sync if last sync was more than 1 hour ago
    final now = DateTime.now();
    final timeSinceLastSync = now.difference(lastSyncAt!);
    return timeSinceLastSync.inHours >= 1;
  }
}
