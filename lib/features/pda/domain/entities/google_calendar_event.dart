class GoogleCalendarEvent {
  final String id;
  final String userId;
  final String googleEventId;
  final String calendarId;
  final String summary;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String status; // confirmed, tentative, cancelled
  final String? visibility; // default, public, private
  final String? recurrenceRule;
  final String? googleMeetLink;
  final String? organizerEmail;
  final String? organizerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoogleCalendarEvent({
    required this.id,
    required this.userId,
    required this.googleEventId,
    required this.calendarId,
    required this.summary,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.status,
    this.visibility,
    this.recurrenceRule,
    this.googleMeetLink,
    this.organizerEmail,
    this.organizerName,
    required this.createdAt,
    required this.updatedAt,
  });

  GoogleCalendarEvent copyWith({
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
    return GoogleCalendarEvent(
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

  bool get hasMeetLink => googleMeetLink != null && googleMeetLink!.isNotEmpty;

  bool get isUpcoming => startTime.isAfter(DateTime.now());

  bool get isOngoing =>
      DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);

  bool get isPast => endTime.isBefore(DateTime.now());

  Duration get duration => endTime.difference(startTime);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleCalendarEvent &&
        other.id == id &&
        other.userId == userId &&
        other.googleEventId == googleEventId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ googleEventId.hashCode;
  }

  @override
  String toString() {
    return 'GoogleCalendarEvent(id: $id, userId: $userId, summary: $summary, startTime: $startTime, hasMeetLink: $hasMeetLink)';
  }
}
