import 'package:equatable/equatable.dart';

class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<String> attendees;
  final String? meetingLink;
  final String? organizerEmail;
  final String? organizerName;
  final bool isAllDay;
  final String? status; // confirmed, tentative, cancelled
  final String? calendarId;
  final DateTime? createdTime;
  final DateTime? updatedTime;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.attendees = const [],
    this.meetingLink,
    this.organizerEmail,
    this.organizerName,
    this.isAllDay = false,
    this.status,
    this.calendarId,
    this.createdTime,
    this.updatedTime,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    startTime,
    endTime,
    location,
    attendees,
    meetingLink,
    organizerEmail,
    organizerName,
    isAllDay,
    status,
    calendarId,
    createdTime,
    updatedTime,
  ];

  // Helper methods
  bool get isUpcoming => startTime.toLocal().isAfter(DateTime.now());
  bool get isPast => endTime.toLocal().isBefore(DateTime.now());
  bool get isOngoing =>
      DateTime.now().isAfter(startTime.toLocal()) &&
      DateTime.now().isBefore(endTime.toLocal());

  Duration get duration => endTime.difference(startTime);

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  String get timeRange {
    final start = _formatTime(startTime.toLocal());
    final end = _formatTime(endTime.toLocal());
    return '$start - $end';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
