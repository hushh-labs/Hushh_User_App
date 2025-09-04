import 'package:equatable/equatable.dart';

class LinkedInAccount extends Equatable {
  final String userId;
  final bool isConnected;
  final String? email;
  final String? profileId;
  final String provider;
  final String? accessToken;
  final String? refreshToken;
  final List<String>? scopes;
  final DateTime? tokenExpiresAt;
  final String? firstName;
  final String? lastName;
  final String? profileUrl;
  final String? profilePictureUrl;
  final String? headline;
  final String? industry;
  final String? location;
  final String? locationName;
  final String? locationCountryCode;
  final String? geoLocationName;
  final String? geoLocationCountryCode;
  final String? vanityName;
  final String? localizedFirstName;
  final String? localizedLastName;
  final String? maidenName;
  final String? phoneticFirstName;
  final String? phoneticLastName;
  final String? formattedName;
  final String? publicProfileUrl;
  final String? profilePictureOriginalUrl;
  final String? backgroundImageUrl;
  final String? summary;
  final String? specialties;
  final DateTime? birthDate;
  final String? ageRange;
  final int numConnections;
  final bool numConnectionsCapped;
  final int numFollowers;
  final String? publicProfileVisibility;
  final Map<String, dynamic>? profileVisibility;
  final DateTime? lastProfileUpdateAt;
  final DateTime? lastSyncAt;
  final Map<String, dynamic>? syncSettings;
  final DateTime? connectedAt;

  const LinkedInAccount({
    required this.userId,
    required this.isConnected,
    this.email,
    this.profileId,
    this.provider = 'linkedin',
    this.accessToken,
    this.refreshToken,
    this.scopes,
    this.tokenExpiresAt,
    this.firstName,
    this.lastName,
    this.profileUrl,
    this.profilePictureUrl,
    this.headline,
    this.industry,
    this.location,
    this.locationName,
    this.locationCountryCode,
    this.geoLocationName,
    this.geoLocationCountryCode,
    this.vanityName,
    this.localizedFirstName,
    this.localizedLastName,
    this.maidenName,
    this.phoneticFirstName,
    this.phoneticLastName,
    this.formattedName,
    this.publicProfileUrl,
    this.profilePictureOriginalUrl,
    this.backgroundImageUrl,
    this.summary,
    this.specialties,
    this.birthDate,
    this.ageRange,
    this.numConnections = 0,
    this.numConnectionsCapped = false,
    this.numFollowers = 0,
    this.publicProfileVisibility,
    this.profileVisibility,
    this.lastProfileUpdateAt,
    this.lastSyncAt,
    this.syncSettings,
    this.connectedAt,
  });

  @override
  List<Object?> get props => [
    userId,
    isConnected,
    email,
    profileId,
    provider,
    accessToken,
    refreshToken,
    scopes,
    tokenExpiresAt,
    firstName,
    lastName,
    profileUrl,
    profilePictureUrl,
    headline,
    industry,
    location,
    locationName,
    locationCountryCode,
    geoLocationName,
    geoLocationCountryCode,
    vanityName,
    localizedFirstName,
    localizedLastName,
    maidenName,
    phoneticFirstName,
    phoneticLastName,
    formattedName,
    publicProfileUrl,
    profilePictureOriginalUrl,
    backgroundImageUrl,
    summary,
    specialties,
    birthDate,
    ageRange,
    numConnections,
    numConnectionsCapped,
    numFollowers,
    publicProfileVisibility,
    profileVisibility,
    lastProfileUpdateAt,
    lastSyncAt,
    syncSettings,
    connectedAt,
  ];

  LinkedInAccount copyWith({
    String? userId,
    bool? isConnected,
    String? email,
    String? profileId,
    String? provider,
    String? accessToken,
    String? refreshToken,
    List<String>? scopes,
    DateTime? tokenExpiresAt,
    String? firstName,
    String? lastName,
    String? profileUrl,
    String? profilePictureUrl,
    String? headline,
    String? industry,
    String? location,
    String? locationName,
    String? locationCountryCode,
    String? geoLocationName,
    String? geoLocationCountryCode,
    String? vanityName,
    String? localizedFirstName,
    String? localizedLastName,
    String? maidenName,
    String? phoneticFirstName,
    String? phoneticLastName,
    String? formattedName,
    String? publicProfileUrl,
    String? profilePictureOriginalUrl,
    String? backgroundImageUrl,
    String? summary,
    String? specialties,
    DateTime? birthDate,
    String? ageRange,
    int? numConnections,
    bool? numConnectionsCapped,
    int? numFollowers,
    String? publicProfileVisibility,
    Map<String, dynamic>? profileVisibility,
    DateTime? lastProfileUpdateAt,
    DateTime? lastSyncAt,
    Map<String, dynamic>? syncSettings,
    DateTime? connectedAt,
  }) {
    return LinkedInAccount(
      userId: userId ?? this.userId,
      isConnected: isConnected ?? this.isConnected,
      email: email ?? this.email,
      profileId: profileId ?? this.profileId,
      provider: provider ?? this.provider,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      scopes: scopes ?? this.scopes,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileUrl: profileUrl ?? this.profileUrl,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      headline: headline ?? this.headline,
      industry: industry ?? this.industry,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      locationCountryCode: locationCountryCode ?? this.locationCountryCode,
      geoLocationName: geoLocationName ?? this.geoLocationName,
      geoLocationCountryCode:
          geoLocationCountryCode ?? this.geoLocationCountryCode,
      vanityName: vanityName ?? this.vanityName,
      localizedFirstName: localizedFirstName ?? this.localizedFirstName,
      localizedLastName: localizedLastName ?? this.localizedLastName,
      maidenName: maidenName ?? this.maidenName,
      phoneticFirstName: phoneticFirstName ?? this.phoneticFirstName,
      phoneticLastName: phoneticLastName ?? this.phoneticLastName,
      formattedName: formattedName ?? this.formattedName,
      publicProfileUrl: publicProfileUrl ?? this.publicProfileUrl,
      profilePictureOriginalUrl:
          profilePictureOriginalUrl ?? this.profilePictureOriginalUrl,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      summary: summary ?? this.summary,
      specialties: specialties ?? this.specialties,
      birthDate: birthDate ?? this.birthDate,
      ageRange: ageRange ?? this.ageRange,
      numConnections: numConnections ?? this.numConnections,
      numConnectionsCapped: numConnectionsCapped ?? this.numConnectionsCapped,
      numFollowers: numFollowers ?? this.numFollowers,
      publicProfileVisibility:
          publicProfileVisibility ?? this.publicProfileVisibility,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      lastProfileUpdateAt: lastProfileUpdateAt ?? this.lastProfileUpdateAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncSettings: syncSettings ?? this.syncSettings,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  /// Check if the account has valid tokens for API access
  bool get hasValidTokens {
    if (accessToken == null) return false;
    if (tokenExpiresAt == null) return true; // Assume valid if no expiry set
    return DateTime.now().isBefore(tokenExpiresAt!);
  }

  /// Get the full name of the LinkedIn user
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return email ?? 'LinkedIn User';
  }

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

    // Sync if last sync was more than 4 hours ago (LinkedIn has stricter rate limits)
    final now = DateTime.now();
    final timeSinceLastSync = now.difference(lastSyncAt!);
    return timeSinceLastSync.inHours >= 4;
  }

  /// Check if token will expire soon (within next hour)
  bool get tokenExpiresSoon {
    if (tokenExpiresAt == null) return false;
    final now = DateTime.now();
    final timeUntilExpiry = tokenExpiresAt!.difference(now);
    return timeUntilExpiry.inMinutes <= 60;
  }
}
