import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/google_calendar_models/google_calendar_event_model.dart';
import '../models/google_calendar_models/google_calendar_attendee_model.dart';

class GoogleCalendarCacheManager {
  static const String _cachePrefix = 'google_calendar_cache_';
  static const String _upcomingEventsKey = '${_cachePrefix}upcoming_events';
  static const String _recentEventsKey = '${_cachePrefix}recent_events';
  static const String _meetingEventsKey = '${_cachePrefix}meeting_events';
  static const String _lastSyncKey = '${_cachePrefix}last_sync';
  static const String _attendeesPrefix = '${_cachePrefix}attendees_';

  // Cache duration settings for optimal PDA performance
  static const Duration _upcomingEventsCacheDuration = Duration(minutes: 15);
  static const Duration _recentEventsCacheDuration = Duration(hours: 2);
  static const Duration _meetingEventsCacheDuration = Duration(minutes: 30);
  static const Duration _attendeesCacheDuration = Duration(hours: 1);

  final SharedPreferences _prefs;

  GoogleCalendarCacheManager(this._prefs);

  /// Cache upcoming events for quick PDA access
  Future<void> cacheUpcomingEvents(
    String userId,
    List<GoogleCalendarEventModel> events,
  ) async {
    try {
      final cacheKey = '${_upcomingEventsKey}_$userId';
      final cacheData = {
        'events': events.map((e) => e.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
      };

      await _prefs.setString(cacheKey, jsonEncode(cacheData));
      debugPrint(
        '📅 [CACHE] Cached ${events.length} upcoming events for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ [CACHE] Error caching upcoming events: $e');
    }
  }

  /// Get cached upcoming events
  Future<List<GoogleCalendarEventModel>?> getCachedUpcomingEvents(
    String userId,
  ) async {
    try {
      final cacheKey = '${_upcomingEventsKey}_$userId';
      final cachedData = _prefs.getString(cacheKey);

      if (cachedData == null) return null;

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] as int,
      );

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) > _upcomingEventsCacheDuration) {
        await _prefs.remove(cacheKey);
        return null;
      }

      final events = (data['events'] as List)
          .map(
            (e) => GoogleCalendarEventModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      debugPrint(
        '📅 [CACHE] Retrieved ${events.length} cached upcoming events',
      );
      return events;
    } catch (e) {
      debugPrint('❌ [CACHE] Error retrieving cached upcoming events: $e');
      return null;
    }
  }

  /// Cache recent events for meeting correlation
  Future<void> cacheRecentEvents(
    String userId,
    List<GoogleCalendarEventModel> events,
  ) async {
    try {
      final cacheKey = '${_recentEventsKey}_$userId';
      final cacheData = {
        'events': events.map((e) => e.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
      };

      await _prefs.setString(cacheKey, jsonEncode(cacheData));
      debugPrint(
        '📅 [CACHE] Cached ${events.length} recent events for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ [CACHE] Error caching recent events: $e');
    }
  }

  /// Get cached recent events
  Future<List<GoogleCalendarEventModel>?> getCachedRecentEvents(
    String userId,
  ) async {
    try {
      final cacheKey = '${_recentEventsKey}_$userId';
      final cachedData = _prefs.getString(cacheKey);

      if (cachedData == null) return null;

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] as int,
      );

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) > _recentEventsCacheDuration) {
        await _prefs.remove(cacheKey);
        return null;
      }

      final events = (data['events'] as List)
          .map(
            (e) => GoogleCalendarEventModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      debugPrint('📅 [CACHE] Retrieved ${events.length} cached recent events');
      return events;
    } catch (e) {
      debugPrint('❌ [CACHE] Error retrieving cached recent events: $e');
      return null;
    }
  }

  /// Cache meeting events (events with Google Meet links)
  Future<void> cacheMeetingEvents(
    String userId,
    List<GoogleCalendarEventModel> events,
  ) async {
    try {
      final cacheKey = '${_meetingEventsKey}_$userId';
      final cacheData = {
        'events': events.map((e) => e.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
      };

      await _prefs.setString(cacheKey, jsonEncode(cacheData));
      debugPrint(
        '🎥 [CACHE] Cached ${events.length} meeting events for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ [CACHE] Error caching meeting events: $e');
    }
  }

  /// Get cached meeting events
  Future<List<GoogleCalendarEventModel>?> getCachedMeetingEvents(
    String userId,
  ) async {
    try {
      final cacheKey = '${_meetingEventsKey}_$userId';
      final cachedData = _prefs.getString(cacheKey);

      if (cachedData == null) return null;

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] as int,
      );

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) > _meetingEventsCacheDuration) {
        await _prefs.remove(cacheKey);
        return null;
      }

      final events = (data['events'] as List)
          .map(
            (e) => GoogleCalendarEventModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      debugPrint('🎥 [CACHE] Retrieved ${events.length} cached meeting events');
      return events;
    } catch (e) {
      debugPrint('❌ [CACHE] Error retrieving cached meeting events: $e');
      return null;
    }
  }

  /// Cache event attendees
  Future<void> cacheEventAttendees(
    String eventId,
    List<GoogleCalendarAttendeeModel> attendees,
  ) async {
    try {
      final cacheKey = '$_attendeesPrefix$eventId';
      final cacheData = {
        'attendees': attendees.map((a) => a.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'eventId': eventId,
      };

      await _prefs.setString(cacheKey, jsonEncode(cacheData));
      debugPrint(
        '👥 [CACHE] Cached ${attendees.length} attendees for event: $eventId',
      );
    } catch (e) {
      debugPrint('❌ [CACHE] Error caching attendees: $e');
    }
  }

  /// Get cached event attendees
  Future<List<GoogleCalendarAttendeeModel>?> getCachedEventAttendees(
    String eventId,
  ) async {
    try {
      final cacheKey = '$_attendeesPrefix$eventId';
      final cachedData = _prefs.getString(cacheKey);

      if (cachedData == null) return null;

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] as int,
      );

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) > _attendeesCacheDuration) {
        await _prefs.remove(cacheKey);
        return null;
      }

      final attendees = (data['attendees'] as List)
          .map(
            (a) =>
                GoogleCalendarAttendeeModel.fromJson(a as Map<String, dynamic>),
          )
          .toList();

      debugPrint('👥 [CACHE] Retrieved ${attendees.length} cached attendees');
      return attendees;
    } catch (e) {
      debugPrint('❌ [CACHE] Error retrieving cached attendees: $e');
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime(String userId) async {
    try {
      final cacheKey = '${_lastSyncKey}_$userId';
      await _prefs.setInt(cacheKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('🔄 [CACHE] Updated last sync time for user: $userId');
    } catch (e) {
      debugPrint('❌ [CACHE] Error updating last sync time: $e');
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime(String userId) async {
    try {
      final cacheKey = '${_lastSyncKey}_$userId';
      final timestamp = _prefs.getInt(cacheKey);

      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('❌ [CACHE] Error getting last sync time: $e');
      return null;
    }
  }

  /// Check if cache needs refresh based on last sync time
  Future<bool> needsRefresh(
    String userId, {
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final lastSync = await getLastSyncTime(userId);
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > maxAge;
  }

  /// Clear all calendar cache for a user
  Future<void> clearUserCache(String userId) async {
    try {
      final keys = [
        '${_upcomingEventsKey}_$userId',
        '${_recentEventsKey}_$userId',
        '${_meetingEventsKey}_$userId',
        '${_lastSyncKey}_$userId',
      ];

      for (final key in keys) {
        await _prefs.remove(key);
      }

      // Clear attendee caches (this is more complex as we need to find all keys)
      final allKeys = _prefs.getKeys();
      final attendeeKeys = allKeys.where(
        (key) => key.startsWith(_attendeesPrefix),
      );

      for (final key in attendeeKeys) {
        await _prefs.remove(key);
      }

      debugPrint('🗑️ [CACHE] Cleared all calendar cache for user: $userId');
    } catch (e) {
      debugPrint('❌ [CACHE] Error clearing user cache: $e');
    }
  }

  /// Clear all calendar cache
  Future<void> clearAllCache() async {
    try {
      final allKeys = _prefs.getKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith(_cachePrefix));

      for (final key in cacheKeys) {
        await _prefs.remove(key);
      }

      debugPrint('🗑️ [CACHE] Cleared all calendar cache');
    } catch (e) {
      debugPrint('❌ [CACHE] Error clearing all cache: $e');
    }
  }

  /// Get cache statistics for debugging
  Future<Map<String, dynamic>> getCacheStats(String userId) async {
    try {
      final upcomingEvents = await getCachedUpcomingEvents(userId);
      final recentEvents = await getCachedRecentEvents(userId);
      final meetingEvents = await getCachedMeetingEvents(userId);
      final lastSync = await getLastSyncTime(userId);

      return {
        'userId': userId,
        'upcomingEventsCount': upcomingEvents?.length ?? 0,
        'recentEventsCount': recentEvents?.length ?? 0,
        'meetingEventsCount': meetingEvents?.length ?? 0,
        'lastSyncTime': lastSync?.toIso8601String(),
        'needsRefresh': await needsRefresh(userId),
      };
    } catch (e) {
      debugPrint('❌ [CACHE] Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }
}
