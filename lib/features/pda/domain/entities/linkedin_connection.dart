import 'package:equatable/equatable.dart';

class LinkedInConnection extends Equatable {
  final int? id;
  final String userId;
  final String connectionId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profileUrl;
  final String? profilePictureUrl;
  final String? headline;
  final String? industry;
  final String? location;
  final String? companyName;
  final String? position;
  final DateTime? connectedAt;
  final int mutualConnectionsCount;
  final DateTime? syncedAt;

  const LinkedInConnection({
    this.id,
    required this.userId,
    required this.connectionId,
    this.firstName,
    this.lastName,
    this.email,
    this.profileUrl,
    this.profilePictureUrl,
    this.headline,
    this.industry,
    this.location,
    this.companyName,
    this.position,
    this.connectedAt,
    this.mutualConnectionsCount = 0,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    connectionId,
    firstName,
    lastName,
    email,
    profileUrl,
    profilePictureUrl,
    headline,
    industry,
    location,
    companyName,
    position,
    connectedAt,
    mutualConnectionsCount,
    syncedAt,
  ];

  LinkedInConnection copyWith({
    int? id,
    String? userId,
    String? connectionId,
    String? firstName,
    String? lastName,
    String? email,
    String? profileUrl,
    String? profilePictureUrl,
    String? headline,
    String? industry,
    String? location,
    String? companyName,
    String? position,
    DateTime? connectedAt,
    int? mutualConnectionsCount,
    DateTime? syncedAt,
  }) {
    return LinkedInConnection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      connectionId: connectionId ?? this.connectionId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profileUrl: profileUrl ?? this.profileUrl,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      headline: headline ?? this.headline,
      industry: industry ?? this.industry,
      location: location ?? this.location,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
      connectedAt: connectedAt ?? this.connectedAt,
      mutualConnectionsCount:
          mutualConnectionsCount ?? this.mutualConnectionsCount,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Get the full name of the connection
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return 'LinkedIn Connection';
  }

  /// Get display name (full name or email fallback)
  String get displayName {
    final name = fullName;
    if (name != 'LinkedIn Connection') return name;
    return email ?? 'LinkedIn Connection';
  }

  /// Get professional summary combining position and company
  String get professionalSummary {
    if (position != null && companyName != null) {
      return '$position at $companyName';
    } else if (position != null) {
      return position!;
    } else if (companyName != null) {
      return companyName!;
    } else if (headline != null) {
      return headline!;
    }
    return '';
  }

  /// Get location display text
  String get locationDisplay {
    return location ?? '';
  }

  /// Check if connection has complete profile information
  bool get hasCompleteProfile {
    return firstName != null &&
        lastName != null &&
        (headline != null || (position != null && companyName != null));
  }

  /// Get initials for avatar fallback
  String get initials {
    String result = '';
    if (firstName != null && firstName!.isNotEmpty) {
      result += firstName![0].toUpperCase();
    }
    if (lastName != null && lastName!.isNotEmpty) {
      result += lastName![0].toUpperCase();
    }
    if (result.isEmpty && email != null && email!.isNotEmpty) {
      result = email![0].toUpperCase();
    }
    return result.isNotEmpty ? result : 'LC';
  }

  /// Format connected date for display
  String get formattedConnectedDate {
    if (connectedAt == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(connectedAt!);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Connected ${years} year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Connected ${months} month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return 'Connected ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Connected today';
    }
  }

  /// Get mutual connections display text
  String get mutualConnectionsDisplay {
    if (mutualConnectionsCount == 0) {
      return 'No mutual connections';
    } else if (mutualConnectionsCount == 1) {
      return '1 mutual connection';
    } else {
      return '$mutualConnectionsCount mutual connections';
    }
  }
}

