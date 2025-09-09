import 'package:flutter/foundation.dart';
import 'package:hushh_user_app/features/pda/data/data_sources/calendar_supabase_data_source.dart';
import 'package:hushh_user_app/features/pda/domain/entities/calendar_event.dart';
import 'package:hushh_user_app/features/pda/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarSupabaseDataSource _dataSource;

  CalendarRepositoryImpl({required CalendarSupabaseDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<List<CalendarEvent>> getCalendarEvents(String userId) async {
    try {
      final models = await _dataSource.getCalendarEvents(userId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ [CALENDAR REPO] Error getting calendar events: $e');
      rethrow;
    }
  }

  @override
  Future<List<CalendarEvent>> getUpcomingEvents(String userId) async {
    try {
      final models = await _dataSource.getUpcomingEvents(userId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ [CALENDAR REPO] Error getting upcoming events: $e');
      rethrow;
    }
  }

  @override
  Future<List<CalendarEvent>> getEventsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final models = await _dataSource.getEventsInRange(
        userId,
        startDate,
        endDate,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ [CALENDAR REPO] Error getting events in range: $e');
      rethrow;
    }
  }

  @override
  Future<List<CalendarEvent>> getTodayEvents(String userId) async {
    try {
      final models = await _dataSource.getTodayEvents(userId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ [CALENDAR REPO] Error getting today\'s events: $e');
      rethrow;
    }
  }

  @override
  Future<List<CalendarEvent>> getEventsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final models = await _dataSource.getEventsForDate(userId, date);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ [CALENDAR REPO] Error getting events for date: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isCalendarConnected(String userId) async {
    try {
      return await _dataSource.isCalendarConnected(userId);
    } catch (e) {
      debugPrint('❌ [CALENDAR REPO] Error checking calendar connection: $e');
      return false;
    }
  }

  @override
  Future<void> refreshCalendarData(String userId) async {
    try {
      await _dataSource.refreshCalendarData(userId);
    } catch (e) {
      debugPrint('❌ [CALENDAR REPO] Error refreshing calendar data: $e');
      rethrow;
    }
  }
}
