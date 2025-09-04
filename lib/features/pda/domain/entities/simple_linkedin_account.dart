class LinkedInAccount {
  final String id;
  final String userId;
  final String linkedinId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? headline;
  final String? profilePictureUrl;
  final String? vanityName;
  final String? locationName;
  final String? locationCountry;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final DateTime connectedAt;
  final DateTime? lastSyncedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LinkedInAccount({
    required this.id,
    required this.userId,
    required this.linkedinId,
    this.email,
    this.firstName,
    this.lastName,
    this.headline,
    this.profilePictureUrl,
    this.vanityName,
    this.locationName,
    this.locationCountry,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    required this.connectedAt,
    this.lastSyncedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getters
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return firstName ?? lastName ?? 'LinkedIn User';
  }

  String get publicProfileUrl {
    if (vanityName != null) {
      return 'https://linkedin.com/in/$vanityName';
    }
    return 'https://linkedin.com';
  }

  bool get hasValidToken {
    if (accessToken == null) return false;
    if (tokenExpiresAt == null) return true; // Assume valid if no expiry
    return DateTime.now().isBefore(tokenExpiresAt!);
  }

  // Factory constructors
  factory LinkedInAccount.fromJson(Map<String, dynamic> json) {
    return LinkedInAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      linkedinId: json['linkedin_id'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      headline: json['headline'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      vanityName: json['vanity_name'] as String?,
      locationName: json['location_name'] as String?,
      locationCountry: json['location_country'] as String?,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.parse(json['token_expires_at'] as String)
          : null,
      connectedAt: DateTime.parse(json['connected_at'] as String),
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'linkedin_id': linkedinId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'headline': headline,
      'profile_picture_url': profilePictureUrl,
      'vanity_name': vanityName,
      'location_name': locationName,
      'location_country': locationCountry,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expires_at': tokenExpiresAt?.toIso8601String(),
      'connected_at': connectedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LinkedInAccount copyWith({
    String? id,
    String? userId,
    String? linkedinId,
    String? email,
    String? firstName,
    String? lastName,
    String? headline,
    String? profilePictureUrl,
    String? vanityName,
    String? locationName,
    String? locationCountry,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    DateTime? connectedAt,
    DateTime? lastSyncedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LinkedInAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      linkedinId: linkedinId ?? this.linkedinId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      headline: headline ?? this.headline,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      vanityName: vanityName ?? this.vanityName,
      locationName: locationName ?? this.locationName,
      locationCountry: locationCountry ?? this.locationCountry,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LinkedInAccount{id: $id, fullName: $fullName, headline: $headline, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkedInAccount &&
        other.id == id &&
        other.linkedinId == linkedinId;
  }

  @override
  int get hashCode => id.hashCode ^ linkedinId.hashCode;
}
