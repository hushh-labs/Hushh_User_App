import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'google_calendar_supabase_data_source.dart';
import '../models/google_calendar_models/google_calendar_event_model.dart';
import '../models/google_calendar_models/google_calendar_attendee_model.dart';

class GoogleCalendarSupabaseDataSourceImpl
    implements GoogleCalendarSupabaseDataSource {
  final SupabaseClient _supabase;

  GoogleCalendarSupabaseDataSourceImpl(this._supabase);

  @override
  Future<List<GoogleCalendarEventModel>> getCalendarEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      debugPrint(
        '📅 [CALENDAR SUPABASE] Getting calendar events for user: $userId',
      );

      // Build the query step by step
      var queryBuilder = _supabase
          .from('google_calendar_events')
          .select('*')
          .eq('userId', userId);

      if (startDate != null) {
        queryBuilder = queryBuilder.gte(
          'start_time',
          startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte(
          'start_time',
          endDate.toIso8601String(),
        );
      }

      // Apply ordering and limit
      var finalQuery = queryBuilder.order('start_time', ascending: true);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      final events = (response as List)
          .map((e) => GoogleCalendarEventModel.fromJson(e))
          .toList();

      debugPrint(
        '📅 [CALENDAR SUPABASE] Found ${events.length} calendar events',
      );

      return events;
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error getting calendar events: $e');
      return [];
    }
  }

  @override
  Future<List<GoogleCalendarEventModel>> getUpcomingEvents(
    String userId, {
    int days = 7,
    int? limit,
  }) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    return getCalendarEvents(
      userId,
      startDate: now,
      endDate: endDate,
      limit: limit,
    );
  }

  @override
  Future<List<GoogleCalendarEventModel>> getRecentEvents(
    String userId, {
    int days = 30,
    int? limit,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    return getCalendarEvents(
      userId,
      startDate: startDate,
      endDate: now,
      limit: limit,
    );
  }

  @override
  Future<List<GoogleCalendarEventModel>> getMeetingEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      debugPrint(
        '🎥 [CALENDAR SUPABASE] Getting meeting events for user: $userId',
      );

      // Build the query step by step
      var queryBuilder = _supabase
          .from('google_calendar_events')
          .select('*')
          .eq('userId', userId)
          .not('google_meet_link', 'is', null);

      if (startDate != null) {
        queryBuilder = queryBuilder.gte(
          'start_time',
          startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte(
          'start_time',
          endDate.toIso8601String(),
        );
      }

      // Apply ordering and limit
      var finalQuery = queryBuilder.order('start_time', ascending: true);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      final events = (response as List)
          .map((e) => GoogleCalendarEventModel.fromJson(e))
          .toList();

      debugPrint(
        '🎥 [CALENDAR SUPABASE] Found ${events.length} meeting events',
      );

      return events;
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error getting meeting events: $e');
      return [];
    }
  }

  @override
  Future<List<GoogleCalendarEventModel>> getTodayEvents(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    debugPrint(
      '📅 [CALENDAR SUPABASE] Getting today events for user: $userId (${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()})',
    );

    return getCalendarEvents(userId, startDate: startOfDay, endDate: endOfDay);
  }

  @override
  Future<List<GoogleCalendarEventModel>> getTomorrowEvents(
    String userId,
  ) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final startOfTomorrow = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
    );
    final endOfTomorrow = startOfTomorrow.add(const Duration(days: 1));

    return getCalendarEvents(
      userId,
      startDate: startOfTomorrow,
      endDate: endOfTomorrow,
    );
  }

  @override
  Future<GoogleCalendarEventModel?> getCalendarEvent(
    String userId,
    String eventId,
  ) async {
    try {
      debugPrint(
        '📅 [CALENDAR SUPABASE] Getting calendar event: $eventId for user: $userId',
      );

      final response = await _supabase
          .from('google_calendar_events')
          .select('*')
          .eq('userId', userId)
          .eq('google_event_id', eventId)
          .maybeSingle();

      if (response == null) {
        debugPrint('📅 [CALENDAR SUPABASE] Event not found: $eventId');
        return null;
      }

      return GoogleCalendarEventModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error getting calendar event: $e');
      return null;
    }
  }

  @override
  Future<List<GoogleCalendarAttendeeModel>> getEventAttendees(
    String userId,
    String eventId,
  ) async {
    try {
      debugPrint(
        '👥 [CALENDAR SUPABASE] Getting attendees for event: $eventId',
      );

      final response = await _supabase
          .from('google_calendar_attendees')
          .select('*')
          .eq('userId', userId)
          .eq('event_id', eventId);

      final attendees = (response as List)
          .map((a) => GoogleCalendarAttendeeModel.fromJson(a))
          .toList();

      debugPrint('👥 [CALENDAR SUPABASE] Found ${attendees.length} attendees');

      return attendees;
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error getting attendees: $e');
      return [];
    }
  }

  @override
  Future<void> storeCalendarEvents(
    String userId,
    List<GoogleCalendarEventModel> events,
  ) async {
    try {
      debugPrint(
        '💾 [CALENDAR SUPABASE] Storing ${events.length} calendar events for user: $userId',
      );

      if (events.isEmpty) return;

      // Convert events to JSON for insertion
      final eventsData = events.map((event) => event.toJson()).toList();

      // Use upsert to handle duplicates
      await _supabase
          .from('google_calendar_events')
          .upsert(eventsData, onConflict: 'userId,google_event_id');

      debugPrint('💾 [CALENDAR SUPABASE] Successfully stored calendar events');
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error storing calendar events: $e');
      throw Exception('Failed to store calendar events: $e');
    }
  }

  @override
  Future<void> storeEventAttendees(
    String userId,
    String eventId,
    List<GoogleCalendarAttendeeModel> attendees,
  ) async {
    try {
      debugPrint(
        '💾 [CALENDAR SUPABASE] Storing ${attendees.length} attendees for event: $eventId',
      );

      if (attendees.isEmpty) return;

      // Convert attendees to JSON for insertion
      final attendeesData = attendees
          .map((attendee) => attendee.toJson())
          .toList();

      // Use upsert to handle duplicates
      await _supabase
          .from('google_calendar_attendees')
          .upsert(attendeesData, onConflict: 'userId,event_id,email');

      debugPrint('💾 [CALENDAR SUPABASE] Successfully stored attendees');
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error storing attendees: $e');
      throw Exception('Failed to store attendees: $e');
    }
  }

  @override
  Future<void> deleteCalendarEvents(String userId) async {
    try {
      debugPrint(
        '🗑️ [CALENDAR SUPABASE] Deleting calendar events for user: $userId',
      );

      // Delete attendees first (foreign key constraint)
      await _supabase
          .from('google_calendar_attendees')
          .delete()
          .eq('userId', userId);

      // Then delete events
      await _supabase
          .from('google_calendar_events')
          .delete()
          .eq('userId', userId);

      debugPrint(
        '🗑️ [CALENDAR SUPABASE] Successfully deleted calendar events',
      );
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error deleting calendar events: $e');
      throw Exception('Failed to delete calendar events: $e');
    }
  }

  @override
  Future<DateTime?> getLastSyncTime(String userId) async {
    try {
      final response = await _supabase
          .from('google_calendar_events')
          .select('updated_at')
          .eq('userId', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return DateTime.parse(response['updated_at'] as String);
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error getting last sync time: $e');
      return null;
    }
  }

  @override
  Future<void> updateLastSyncTime(String userId, DateTime syncTime) async {
    try {
      // This could be implemented by updating a separate sync status table
      // For now, we'll rely on the updated_at timestamps on the events
      debugPrint(
        '🔄 [CALENDAR SUPABASE] Last sync time updated for user: $userId at $syncTime',
      );
    } catch (e) {
      debugPrint('❌ [CALENDAR SUPABASE] Error updating last sync time: $e');
    }
  }
}
