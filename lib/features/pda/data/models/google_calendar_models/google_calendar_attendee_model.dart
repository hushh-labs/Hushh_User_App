import '../../../domain/entities/google_calendar_attendee.dart';

class GoogleCalendarAttendeeModel extends GoogleCalendarAttendee {
  const GoogleCalendarAttendeeModel({
    required super.id,
    required super.userId,
    required super.eventId,
    required super.email,
    super.displayName,
    required super.responseStatus,
    required super.isOrganizer,
    required super.isOptional,
    required super.createdAt,
  });

  factory GoogleCalendarAttendeeModel.fromJson(Map<String, dynamic> json) {
    return GoogleCalendarAttendeeModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventId: json['event_id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      responseStatus: json['response_status'] as String,
      isOrganizer: json['is_organizer'] as bool,
      isOptional: json['is_optional'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory GoogleCalendarAttendeeModel.fromGoogleApiJson(
    Map<String, dynamic> json,
    String userId,
    String eventId,
  ) {
    return GoogleCalendarAttendeeModel(
      id: '', // Will be set by repository
      userId: userId,
      eventId: eventId,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      responseStatus: json['responseStatus'] as String? ?? 'needsAction',
      isOrganizer: json['organizer'] as bool? ?? false,
      isOptional: json['optional'] as bool? ?? false,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'event_id': eventId,
      'email': email,
      'display_name': displayName,
      'response_status': responseStatus,
      'is_organizer': isOrganizer,
      'is_optional': isOptional,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GoogleCalendarAttendeeModel copyWith({
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
    return GoogleCalendarAttendeeModel(
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
}
