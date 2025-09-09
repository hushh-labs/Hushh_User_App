import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar_event_model.dart';
import 'calendar_supabase_data_source.dart';

class CalendarSupabaseDataSourceImpl implements CalendarSupabaseDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<CalendarEventModel>> getCalendarEvents(String userId) async {
    try {
      debugPrint(
        '📅 [CALENDAR] Fetching all calendar events for user: $userId',
      );

      final response = await _supabase
          .from('google_calendar_events')
          .select('*')
          .eq('userId', userId)
          .order('start_time', ascending: true);

      final events = (response as List)
          .map((json) => CalendarEventModel.fromJson(json))
          .toList();

      debugPrint('📅 [CALENDAR] Fetched ${events.length} calendar events');
      return events;
    } catch (e) {
      debugPrint('❌ [CALENDAR] Error fetching calendar events: $e');
      rethrow;
    }
  }

  @override
  Future<List<CalendarEventModel>> getUpcomingEvents(String userId) async {
    try {
      debugPrint('📅 [CALENDAR] Fetching upcoming events for user: $userId');

      final now = DateTime.now();
      final weekFromNow = now.add(const Duration(days: 7));

      final response = await _supabase
          .from('google_calendar_events')
          .select('*')
          .eq('userId', userId)
          .gte('start_time', now.toUtc().toIso8601String())
          .lte('start_time', weekFromNow.toUtc().toIso8601String())
          .order('start_time', ascending: true);

      final events = (response as List)
          .map((json) => CalendarEventModel.fromJson(json))
          .toList();

      debugPrint('📅 [CALENDAR] Fetched ${events.length} upcoming events');
      return events;
    } catch (e) {
      debugPrint('❌ [CALENDAR] Error fetching upcoming events: $e');
      rethrow;
    }
  }

  @override
  Future<List<CalendarEventModel>> getEventsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint('📅 [CALENDAR] Fetching events in range for user: $userId');

      final response = await _supabase
          .from('google_calendar_events')
          .select('*')
          .eq('userId', userId)
          .gte('start_time', startDate.toUtc().toIso8601String())
          .lte('end_time', endDate.toUtc().toIso8601String())
          .order('start_time', ascending: true);

      final events = (response as List)
          .map((json) => CalendarEventModel.fromJson(json))
          .toList();

      debugPrint('📅 [CALENDAR] Fetched ${events.length} events in range');
      return events;
    } catch (e) {
      debugPrint('❌ [CALENDAR] Error fetching events in range: $e');
      rethrow;
    }
  }

  @override
  Future<List<CalendarEventModel>> getTodayEvents(String userId) async {
    try {
      debugPrint('📅 [CALENDAR] Fetching today\'s events for user: $userId');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('google_calendar_events')
          .select('*')
          .eq('userId', userId)
          .gte('start_time', startOfDay.toUtc().toIso8601String())
          .lt('start_time', endOfDay.toUtc().toIso8601String())
          .order('start_time', ascending: true);

      final events = (response as List)
          .map((json) => CalendarEventModel.fromJson(json))
          .toList();

      debugPrint('📅 [CALENDAR] Fetched ${events.length} events for today');
      return events;
    } catch (e) {
      debugPrint('❌ [CALENDAR] Error fetching today\'s events: $e');
      rethrow;
    }
  }

  @override
  Future<List<CalendarEventModel>> getEventsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      debugPrint('📅 [CALENDAR] Fetching events for date: $date');

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('google_calendar_events')
          .select('*')
          .eq('userId', userId)
          .gte('start_time', startOfDay.toUtc().toIso8601String())
          .lt('start_time', endOfDay.toUtc().toIso8601String())
          .order('start_time', ascending: true);

      final events = (response as List)
          .map((json) => CalendarEventModel.fromJson(json))
          .toList();

      debugPrint('📅 [CALENDAR] Fetched ${events.length} events for date');
      return events;
    } catch (e) {
      debugPrint('❌ [CALENDAR] Error fetching events for date: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isCalendarConnected(String userId) async {
    try {
      debugPrint(
        '📅 [CALENDAR] Checking calendar connection status for user: $userId',
      );

      final response = await _supabase
          .from('google_meet_accounts')
          .select('is_active')
          .eq('user_id', userId)
          .single();

      final isConnected = response['is_active'] as bool? ?? false;
      debugPrint('📅 [CALENDAR] Calendar connected: $isConnected');
      return isConnected;
    } catch (e) {
      debugPrint('❌ [CALENDAR] Error checking calendar connection: $e');
      return false;
    }
  }

  @override
  Future<void> refreshCalendarData(String userId) async {
    try {
      debugPrint('📅 [CALENDAR] Refreshing calendar data for user: $userId');

      // Call the Google Meet sync function to refresh calendar data
      final response = await _supabase.functions.invoke(
        'google-meet-sync',
        body: {'action': 'sync', 'userId': userId},
      );

      if (response.status != 200) {
        throw Exception('Failed to refresh calendar data: ${response.data}');
      }

      debugPrint('📅 [CALENDAR] Calendar data refreshed successfully');
    } catch (e) {
      debugPrint('❌ [CALENDAR] Error refreshing calendar data: $e');
      rethrow;
    }
  }
}
