import 'package:hushh_user_app/features/pda/domain/entities/calendar_event.dart';

class CalendarEventModel extends CalendarEvent {
  const CalendarEventModel({
    required super.id,
    required super.title,
    super.description,
    required super.startTime,
    required super.endTime,
    super.location,
    super.attendees = const [],
    super.meetingLink,
    super.organizerEmail,
    super.organizerName,
    super.isAllDay = false,
    super.status,
    super.calendarId,
    super.createdTime,
    super.updatedTime,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      title: json['summary'] as String? ?? 'No Title',
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      location: json['location'] as String?,
      attendees: const [], // Will be fetched separately from attendees table
      meetingLink: json['google_meet_link'] as String?,
      organizerEmail: json['organizer_email'] as String?,
      organizerName: json['organizer_name'] as String?,
      isAllDay: (json['is_all_day'] as bool?) ?? false,
      status: json['status'] as String?,
      calendarId: json['calendar_id'] as String?,
      createdTime: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedTime: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'summary': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'attendees': attendees,
      'google_meet_link': meetingLink,
      'organizer_email': organizerEmail,
      'organizer_name': organizerName,
      'is_all_day': isAllDay,
      'status': status,
      'calendar_id': calendarId,
      'created_at': createdTime?.toIso8601String(),
      'updated_at': updatedTime?.toIso8601String(),
    };
  }

  CalendarEvent toEntity() => CalendarEvent(
    id: id,
    title: title,
    description: description,
    startTime: startTime,
    endTime: endTime,
    location: location,
    attendees: attendees,
    meetingLink: meetingLink,
    organizerEmail: organizerEmail,
    organizerName: organizerName,
    isAllDay: isAllDay,
    status: status,
    calendarId: calendarId,
    createdTime: createdTime,
    updatedTime: updatedTime,
  );
}
