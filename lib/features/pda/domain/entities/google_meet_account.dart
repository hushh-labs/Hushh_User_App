class GoogleMeetAccount {
  final String id;
  final String userId;
  final String googleAccountId;
  final String email;
  final String? displayName;
  final String? profilePictureUrl;
  final DateTime connectedAt;
  final DateTime? lastSyncedAt;
  final bool isActive;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;

  const GoogleMeetAccount({
    required this.id,
    required this.userId,
    required this.googleAccountId,
    required this.email,
    this.displayName,
    this.profilePictureUrl,
    required this.connectedAt,
    this.lastSyncedAt,
    required this.isActive,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
  });

  GoogleMeetAccount copyWith({
    String? id,
    String? userId,
    String? googleAccountId,
    String? email,
    String? displayName,
    String? profilePictureUrl,
    DateTime? connectedAt,
    DateTime? lastSyncedAt,
    bool? isActive,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
  }) {
    return GoogleMeetAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      googleAccountId: googleAccountId ?? this.googleAccountId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isActive: isActive ?? this.isActive,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleMeetAccount &&
        other.id == id &&
        other.userId == userId &&
        other.googleAccountId == googleAccountId &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        googleAccountId.hashCode ^
        email.hashCode;
  }

  @override
  String toString() {
    return 'GoogleMeetAccount(id: $id, userId: $userId, email: $email, isActive: $isActive)';
  }
}
