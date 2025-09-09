import '../entities/calendar_event.dart';

abstract class CalendarRepository {
  // Fetch all calendar events for a user
  Future<List<CalendarEvent>> getCalendarEvents(String userId);

  // Fetch upcoming events (next 7 days)
  Future<List<CalendarEvent>> getUpcomingEvents(String userId);

  // Fetch events for a specific date range
  Future<List<CalendarEvent>> getEventsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  // Fetch events for today
  Future<List<CalendarEvent>> getTodayEvents(String userId);

  // Fetch events for a specific date
  Future<List<CalendarEvent>> getEventsForDate(String userId, DateTime date);

  // Check if calendar is connected
  Future<bool> isCalendarConnected(String userId);

  // Refresh/sync calendar data
  Future<void> refreshCalendarData(String userId);
}
