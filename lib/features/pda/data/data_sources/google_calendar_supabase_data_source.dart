import '../models/google_calendar_models/google_calendar_event_model.dart';
import '../models/google_calendar_models/google_calendar_attendee_model.dart';

abstract class GoogleCalendarSupabaseDataSource {
  /// Get calendar events for a user from Supabase database
  Future<List<GoogleCalendarEventModel>> getCalendarEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Get upcoming calendar events for a user
  Future<List<GoogleCalendarEventModel>> getUpcomingEvents(
    String userId, {
    int days = 7,
    int? limit,
  });

  /// Get recent calendar events for a user
  Future<List<GoogleCalendarEventModel>> getRecentEvents(
    String userId, {
    int days = 30,
    int? limit,
  });

  /// Get calendar events with Google Meet links
  Future<List<GoogleCalendarEventModel>> getMeetingEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Get calendar events for today
  Future<List<GoogleCalendarEventModel>> getTodayEvents(String userId);

  /// Get calendar events for tomorrow
  Future<List<GoogleCalendarEventModel>> getTomorrowEvents(String userId);

  /// Get a specific calendar event by ID
  Future<GoogleCalendarEventModel?> getCalendarEvent(
    String userId,
    String eventId,
  );

  /// Get attendees for a specific event
  Future<List<GoogleCalendarAttendeeModel>> getEventAttendees(
    String userId,
    String eventId,
  );

  /// Store calendar events in Supabase database
  Future<void> storeCalendarEvents(
    String userId,
    List<GoogleCalendarEventModel> events,
  );

  /// Store event attendees in Supabase database
  Future<void> storeEventAttendees(
    String userId,
    String eventId,
    List<GoogleCalendarAttendeeModel> attendees,
  );

  /// Delete calendar events for a user
  Future<void> deleteCalendarEvents(String userId);

  /// Get calendar sync status for a user
  Future<DateTime?> getLastSyncTime(String userId);

  /// Update calendar sync status for a user
  Future<void> updateLastSyncTime(String userId, DateTime syncTime);
}
