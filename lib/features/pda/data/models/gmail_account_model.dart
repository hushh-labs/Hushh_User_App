import '../../domain/entities/gmail_account.dart';

class GmailAccountModel extends GmailAccount {
  const GmailAccountModel({
    required super.userId,
    required super.isConnected,
    required super.email,
    super.provider = 'gmail',
    super.accessToken,
    super.refreshToken,
    super.idToken,
    super.scopes,
    super.historyId,
    super.lastSyncAt,
    super.syncSettings,
    super.connectedAt,
  });

  factory GmailAccountModel.fromJson(Map<String, dynamic> json) {
    return GmailAccountModel(
      userId: json['userId'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
      email: json['email'] as String?,
      provider: json['provider'] as String? ?? 'gmail',
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      idToken: json['idToken'] as String?,
      scopes: (json['scopes'] as List?)?.cast<String>(),
      historyId: json['historyId'] as String?,
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
      syncSettings: json['syncSettings'] as Map<String, dynamic>?,
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isConnected': isConnected,
      'email': email,
      'provider': provider,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'idToken': idToken,
      'scopes': scopes,
      'historyId': historyId,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'syncSettings': syncSettings ?? {},
      'connectedAt': connectedAt?.toIso8601String(),
    };
  }

  factory GmailAccountModel.fromEntity(GmailAccount entity) {
    return GmailAccountModel(
      userId: entity.userId,
      isConnected: entity.isConnected,
      email: entity.email,
      provider: entity.provider,
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      idToken: entity.idToken,
      scopes: entity.scopes,
      historyId: entity.historyId,
      lastSyncAt: entity.lastSyncAt,
      syncSettings: entity.syncSettings,
      connectedAt: entity.connectedAt,
    );
  }

  GmailAccount toEntity() {
    return GmailAccount(
      userId: userId,
      isConnected: isConnected,
      email: email,
      provider: provider,
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      scopes: scopes,
      historyId: historyId,
      lastSyncAt: lastSyncAt,
      syncSettings: syncSettings,
      connectedAt: connectedAt,
    );
  }

  @override
  GmailAccountModel copyWith({
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
    return GmailAccountModel(
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
}
