import '../../../domain/entities/google_calendar_event.dart';

class GoogleCalendarEventModel extends GoogleCalendarEvent {
  const GoogleCalendarEventModel({
    required super.id,
    required super.userId,
    required super.googleEventId,
    required super.calendarId,
    required super.summary,
    super.description,
    super.location,
    required super.startTime,
    required super.endTime,
    required super.isAllDay,
    required super.status,
    super.visibility,
    super.recurrenceRule,
    super.googleMeetLink,
    super.organizerEmail,
    super.organizerName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GoogleCalendarEventModel.fromJson(Map<String, dynamic> json) {
    return GoogleCalendarEventModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      googleEventId: json['google_event_id'] as String,
      calendarId: json['calendar_id'] as String,
      summary: json['summary'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      isAllDay: json['is_all_day'] as bool,
      status: json['status'] as String,
      visibility: json['visibility'] as String?,
      recurrenceRule: json['recurrence_rule'] as String?,
      googleMeetLink: json['google_meet_link'] as String?,
      organizerEmail: json['organizer_email'] as String?,
      organizerName: json['organizer_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory GoogleCalendarEventModel.fromGoogleApiJson(
    Map<String, dynamic> json,
    String userId,
  ) {
    // Extract Google Meet link from various possible locations
    String? meetLink;

    // Check hangoutLink field
    if (json['hangoutLink'] != null) {
      meetLink = json['hangoutLink'] as String;
    }

    // Check conferenceData
    if (meetLink == null && json['conferenceData'] != null) {
      final conferenceData = json['conferenceData'] as Map<String, dynamic>;
      if (conferenceData['entryPoints'] != null) {
        final entryPoints = conferenceData['entryPoints'] as List;
        for (final entryPoint in entryPoints) {
          if (entryPoint['entryPointType'] == 'video' &&
              entryPoint['uri'] != null &&
              (entryPoint['uri'] as String).contains('meet.google.com')) {
            meetLink = entryPoint['uri'] as String;
            break;
          }
        }
      }
    }

    // Check description for meet links
    if (meetLink == null && json['description'] != null) {
      final description = json['description'] as String;
      final meetRegex = RegExp(r'https://meet\.google\.com/[a-z-]+');
      final match = meetRegex.firstMatch(description);
      if (match != null) {
        meetLink = match.group(0);
      }
    }

    // Parse start and end times
    final start = json['start'] as Map<String, dynamic>;
    final end = json['end'] as Map<String, dynamic>;

    DateTime startTime;
    DateTime endTime;
    bool isAllDay = false;

    if (start['date'] != null) {
      // All-day event
      startTime = DateTime.parse(start['date'] as String);
      endTime = DateTime.parse(end['date'] as String);
      isAllDay = true;
    } else {
      // Timed event
      startTime = DateTime.parse(start['dateTime'] as String);
      endTime = DateTime.parse(end['dateTime'] as String);
    }

    // Extract organizer information
    final organizer = json['organizer'] as Map<String, dynamic>?;

    return GoogleCalendarEventModel(
      id: '', // Will be set by repository
      userId: userId,
      googleEventId: json['id'] as String,
      calendarId: json['organizer']?['email'] as String? ?? 'primary',
      summary: json['summary'] as String? ?? 'No Title',
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      status: json['status'] as String? ?? 'confirmed',
      visibility: json['visibility'] as String?,
      recurrenceRule: (json['recurrence'] as List?)?.join(','),
      googleMeetLink: meetLink,
      organizerEmail: organizer?['email'] as String?,
      organizerName: organizer?['displayName'] as String?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'google_event_id': googleEventId,
      'calendar_id': calendarId,
      'summary': summary,
      'description': description,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_all_day': isAllDay,
      'status': status,
      'visibility': visibility,
      'recurrence_rule': recurrenceRule,
      'google_meet_link': googleMeetLink,
      'organizer_email': organizerEmail,
      'organizer_name': organizerName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GoogleCalendarEventModel copyWith({
    String? id,
    String? userId,
    String? googleEventId,
    String? calendarId,
    String? summary,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? status,
    String? visibility,
    String? recurrenceRule,
    String? googleMeetLink,
    String? organizerEmail,
    String? organizerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoogleCalendarEventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      googleEventId: googleEventId ?? this.googleEventId,
      calendarId: calendarId ?? this.calendarId,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      googleMeetLink: googleMeetLink ?? this.googleMeetLink,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      organizerName: organizerName ?? this.organizerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
