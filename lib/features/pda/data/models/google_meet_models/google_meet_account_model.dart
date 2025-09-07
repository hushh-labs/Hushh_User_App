import '../../../domain/entities/google_meet_account.dart';

class GoogleMeetAccountModel {
  final String id;
  final String userId;
  final String googleAccountId;
  final String email;
  final String? displayName;
  final String? profilePictureUrl;
  final String connectedAt;
  final String? lastSyncedAt;
  final bool isActive;
  final String? accessTokenEncrypted;
  final String? refreshTokenEncrypted;
  final String? tokenExpiresAt;
  final String createdAt;
  final String updatedAt;

  const GoogleMeetAccountModel({
    required this.id,
    required this.userId,
    required this.googleAccountId,
    required this.email,
    this.displayName,
    this.profilePictureUrl,
    required this.connectedAt,
    this.lastSyncedAt,
    required this.isActive,
    this.accessTokenEncrypted,
    this.refreshTokenEncrypted,
    this.tokenExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoogleMeetAccountModel.fromJson(Map<String, dynamic> json) {
    return GoogleMeetAccountModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      googleAccountId: json['google_account_id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'],
      profilePictureUrl: json['profile_picture_url'],
      connectedAt: json['connected_at'] ?? '',
      lastSyncedAt: json['last_synced_at'],
      isActive: json['is_active'] ?? true,
      accessTokenEncrypted: json['access_token_encrypted'],
      refreshTokenEncrypted: json['refresh_token_encrypted'],
      tokenExpiresAt: json['token_expires_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'google_account_id': googleAccountId,
      'email': email,
      'display_name': displayName,
      'profile_picture_url': profilePictureUrl,
      'connected_at': connectedAt,
      'last_synced_at': lastSyncedAt,
      'is_active': isActive,
      'access_token_encrypted': accessTokenEncrypted,
      'refresh_token_encrypted': refreshTokenEncrypted,
      'token_expires_at': tokenExpiresAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  GoogleMeetAccount toEntity() {
    return GoogleMeetAccount(
      id: id,
      userId: userId,
      googleAccountId: googleAccountId,
      email: email,
      displayName: displayName,
      profilePictureUrl: profilePictureUrl,
      connectedAt: _parseDateTime(connectedAt) ?? DateTime.now(),
      lastSyncedAt: lastSyncedAt != null ? _parseDateTime(lastSyncedAt!) : null,
      isActive: isActive,
      accessToken: null, // Don't expose encrypted tokens in entity
      refreshToken: null,
      tokenExpiresAt: tokenExpiresAt != null
          ? _parseDateTime(tokenExpiresAt!)
          : null,
    );
  }

  /// Helper method to safely parse DateTime strings
  DateTime? _parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // If parsing fails, return null instead of throwing
      return null;
    }
  }

  factory GoogleMeetAccountModel.fromEntity(GoogleMeetAccount entity) {
    return GoogleMeetAccountModel(
      id: entity.id,
      userId: entity.userId,
      googleAccountId: entity.googleAccountId,
      email: entity.email,
      displayName: entity.displayName,
      profilePictureUrl: entity.profilePictureUrl,
      connectedAt: entity.connectedAt.toIso8601String(),
      lastSyncedAt: entity.lastSyncedAt?.toIso8601String(),
      isActive: entity.isActive,
      accessTokenEncrypted: null, // Handle encryption separately
      refreshTokenEncrypted: null,
      tokenExpiresAt: entity.tokenExpiresAt?.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}
