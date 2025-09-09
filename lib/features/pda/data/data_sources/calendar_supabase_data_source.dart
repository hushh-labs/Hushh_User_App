import '../models/calendar_event_model.dart';

abstract class CalendarSupabaseDataSource {
  Future<List<CalendarEventModel>> getCalendarEvents(String userId);
  Future<List<CalendarEventModel>> getUpcomingEvents(String userId);
  Future<List<CalendarEventModel>> getEventsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<CalendarEventModel>> getTodayEvents(String userId);
  Future<List<CalendarEventModel>> getEventsForDate(
    String userId,
    DateTime date,
  );
  Future<bool> isCalendarConnected(String userId);
  Future<void> refreshCalendarData(String userId);
}
