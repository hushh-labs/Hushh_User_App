class GoogleCalendarAttendee {
  final String id;
  final String userId;
  final String eventId;
  final String email;
  final String? displayName;
  final String responseStatus; // needsAction, declined, tentative, accepted
  final bool isOrganizer;
  final bool isOptional;
  final DateTime createdAt;

  const GoogleCalendarAttendee({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.email,
    this.displayName,
    required this.responseStatus,
    required this.isOrganizer,
    required this.isOptional,
    required this.createdAt,
  });

  GoogleCalendarAttendee copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? email,
    String? displayName,
    String? responseStatus,
    bool? isOrganizer,
    bool? isOptional,
    DateTime? createdAt,
  }) {
    return GoogleCalendarAttendee(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      responseStatus: responseStatus ?? this.responseStatus,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      isOptional: isOptional ?? this.isOptional,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasAccepted => responseStatus == 'accepted';
  bool get hasDeclined => responseStatus == 'declined';
  bool get isTentative => responseStatus == 'tentative';
  bool get needsAction => responseStatus == 'needsAction';

  String get displayNameOrEmail => displayName ?? email;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleCalendarAttendee &&
        other.id == id &&
        other.userId == userId &&
        other.eventId == eventId &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ eventId.hashCode ^ email.hashCode;
  }

  @override
  String toString() {
    return 'GoogleCalendarAttendee(id: $id, email: $email, displayName: $displayName, responseStatus: $responseStatus, isOrganizer: $isOrganizer)';
  }
}
