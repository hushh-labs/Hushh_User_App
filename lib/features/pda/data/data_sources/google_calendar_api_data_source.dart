import '../models/google_calendar_models/google_calendar_event_model.dart';
import '../models/google_calendar_models/google_calendar_attendee_model.dart';

abstract class GoogleCalendarApiDataSource {
  /// Fetch calendar events from Google Calendar API
  /// [accessToken] - OAuth2 access token
  /// [timeMin] - Lower bound for event start time (RFC3339 timestamp)
  /// [timeMax] - Upper bound for event start time (RFC3339 timestamp)
  /// [maxResults] - Maximum number of events to return
  Future<List<GoogleCalendarEventModel>> fetchCalendarEvents(
    String accessToken, {
    DateTime? timeMin,
    DateTime? timeMax,
    int maxResults = 250,
  });

  /// Fetch events with Google Meet links specifically
  /// This is optimized for PDA context gathering
  Future<List<GoogleCalendarEventModel>> fetchMeetingEvents(
    String accessToken, {
    DateTime? timeMin,
    DateTime? timeMax,
    int maxResults = 100,
  });

  /// Fetch attendees for a specific calendar event
  Future<List<GoogleCalendarAttendeeModel>> fetchEventAttendees(
    String accessToken,
    String eventId,
  );

  /// Get a specific calendar event by ID
  Future<GoogleCalendarEventModel?> getCalendarEvent(
    String accessToken,
    String eventId,
  );

  /// Fetch upcoming events (next 7 days) for quick PDA context
  Future<List<GoogleCalendarEventModel>> fetchUpcomingEvents(
    String accessToken, {
    int days = 7,
    int maxResults = 50,
  });

  /// Fetch recent events (last 30 days) for meeting correlation
  Future<List<GoogleCalendarEventModel>> fetchRecentEvents(
    String accessToken, {
    int days = 30,
    int maxResults = 100,
  });

  /// Check if access token is valid by making a test API call
  Future<bool> isTokenValid(String accessToken);

  /// Refresh access token using refresh token
  Future<void> refreshAccessToken(String refreshToken);
}
