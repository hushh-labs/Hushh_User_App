import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'google_calendar_api_data_source.dart';
import '../models/google_calendar_models/google_calendar_event_model.dart';
import '../models/google_calendar_models/google_calendar_attendee_model.dart';

class GoogleCalendarApiDataSourceImpl implements GoogleCalendarApiDataSource {
  static const String _baseUrl = 'https://www.googleapis.com/calendar/v3';
  final http.Client _httpClient;

  GoogleCalendarApiDataSourceImpl({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  Future<List<GoogleCalendarEventModel>> fetchCalendarEvents(
    String accessToken, {
    DateTime? timeMin,
    DateTime? timeMax,
    int maxResults = 250,
  }) async {
    try {
      debugPrint('📅 [CALENDAR API] Fetching calendar events...');

      final queryParams = <String, String>{
        'maxResults': maxResults.toString(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
      };

      if (timeMin != null) {
        queryParams['timeMin'] = timeMin.toUtc().toIso8601String();
      }
      if (timeMax != null) {
        queryParams['timeMax'] = timeMax.toUtc().toIso8601String();
      }

      final uri = Uri.parse(
        '$_baseUrl/calendars/primary/events',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final events = data['items'] as List<dynamic>? ?? [];

        debugPrint('📅 [CALENDAR API] Found ${events.length} events');

        return events
            .map(
              (event) => GoogleCalendarEventModel.fromGoogleApiJson(
                event as Map<String, dynamic>,
                '', // userId will be set by repository
              ),
            )
            .toList();
      } else {
        throw Exception(
          'Calendar API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [CALENDAR API] Error fetching events: $e');
      throw Exception('Failed to fetch calendar events: $e');
    }
  }

  @override
  Future<List<GoogleCalendarEventModel>> fetchMeetingEvents(
    String accessToken, {
    DateTime? timeMin,
    DateTime? timeMax,
    int maxResults = 100,
  }) async {
    try {
      debugPrint(
        '🎥 [CALENDAR API] Fetching meeting events with Google Meet links...',
      );

      // First fetch all events
      final allEvents = await fetchCalendarEvents(
        accessToken,
        timeMin: timeMin,
        timeMax: timeMax,
        maxResults: maxResults * 2, // Fetch more to filter for meet links
      );

      // Filter events that have Google Meet links
      final meetingEvents = allEvents
          .where((event) => event.hasMeetLink)
          .take(maxResults)
          .toList();

      debugPrint(
        '🎥 [CALENDAR API] Found ${meetingEvents.length} events with Meet links',
      );

      return meetingEvents;
    } catch (e) {
      debugPrint('❌ [CALENDAR API] Error fetching meeting events: $e');
      throw Exception('Failed to fetch meeting events: $e');
    }
  }

  @override
  Future<List<GoogleCalendarAttendeeModel>> fetchEventAttendees(
    String accessToken,
    String eventId,
  ) async {
    try {
      debugPrint('👥 [CALENDAR API] Fetching attendees for event: $eventId');

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final attendees = data['attendees'] as List<dynamic>? ?? [];

        return attendees
            .map(
              (attendee) => GoogleCalendarAttendeeModel.fromGoogleApiJson(
                attendee as Map<String, dynamic>,
                '', // userId will be set by repository
                eventId,
              ),
            )
            .toList();
      } else {
        throw Exception(
          'Calendar API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [CALENDAR API] Error fetching attendees: $e');
      throw Exception('Failed to fetch event attendees: $e');
    }
  }

  @override
  Future<GoogleCalendarEventModel?> getCalendarEvent(
    String accessToken,
    String eventId,
  ) async {
    try {
      debugPrint('📅 [CALENDAR API] Fetching event: $eventId');

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/calendars/primary/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GoogleCalendarEventModel.fromGoogleApiJson(
          data,
          '', // userId will be set by repository
        );
      } else if (response.statusCode == 404) {
        return null; // Event not found
      } else {
        throw Exception(
          'Calendar API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [CALENDAR API] Error fetching event: $e');
      throw Exception('Failed to fetch calendar event: $e');
    }
  }

  @override
  Future<List<GoogleCalendarEventModel>> fetchUpcomingEvents(
    String accessToken, {
    int days = 7,
    int maxResults = 50,
  }) async {
    final now = DateTime.now();
    final timeMax = now.add(Duration(days: days));

    return fetchMeetingEvents(
      accessToken,
      timeMin: now,
      timeMax: timeMax,
      maxResults: maxResults,
    );
  }

  @override
  Future<List<GoogleCalendarEventModel>> fetchRecentEvents(
    String accessToken, {
    int days = 30,
    int maxResults = 100,
  }) async {
    final now = DateTime.now();
    final timeMin = now.subtract(Duration(days: days));

    return fetchMeetingEvents(
      accessToken,
      timeMin: timeMin,
      timeMax: now,
      maxResults: maxResults,
    );
  }

  @override
  Future<bool> isTokenValid(String accessToken) async {
    try {
      // Test token validity by making a simple API call
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/calendars/primary'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [CALENDAR API] Error validating token: $e');
      return false;
    }
  }

  @override
  Future<void> refreshAccessToken(String refreshToken) async {
    try {
      debugPrint('🔄 [CALENDAR API] Refreshing access token...');

      // This would typically call Google's token refresh endpoint
      // For now, throw an error indicating this needs to be implemented
      // with proper OAuth2 flow
      throw UnimplementedError(
        'Token refresh needs to be implemented with Google OAuth2 endpoints. '
        'This should be handled by the unified OAuth service.',
      );
    } catch (e) {
      debugPrint('❌ [CALENDAR API] Error refreshing token: $e');
      throw Exception('Failed to refresh access token: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
