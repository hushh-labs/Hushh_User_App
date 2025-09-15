import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data_sources/google_calendar_api_data_source.dart';
import '../data_sources/google_calendar_supabase_data_source.dart';
import '../data_sources/google_meet_supabase_data_source.dart';
import 'google_calendar_cache_manager.dart';
import '../models/google_calendar_models/google_calendar_event_model.dart';

class GoogleCalendarContextPrewarmService {
  final GoogleCalendarApiDataSource _calendarApiDataSource;
  final GoogleCalendarSupabaseDataSource _calendarSupabaseDataSource;
  final GoogleMeetSupabaseDataSource _supabaseDataSource;
  final GoogleCalendarCacheManager _cacheManager;
  final SharedPreferences _prefs;

  static const String _contextCacheKey = 'pda_calendar_context_cache';
  static const String _lastPrewarmKey = 'pda_calendar_last_prewarm';
  static const Duration _prewarmInterval = Duration(minutes: 30);

  GoogleCalendarContextPrewarmService(
    this._calendarApiDataSource,
    this._calendarSupabaseDataSource,
    this._supabaseDataSource,
    this._cacheManager,
    this._prefs,
  );

  /// Prewarm PDA with calendar and meeting context on app startup
  Future<void> prewarmOnStartup(String userId) async {
    try {
      debugPrint(
        '🚀 [CALENDAR PREWARM] Starting startup prewarm for user: $userId',
      );

      // Always prewarm on startup - no interval check
      debugPrint('🔄 [CALENDAR PREWARM] Force prewarming on startup');

      // Try to get cached data first for immediate PDA availability
      await _loadCachedContextForPDA(userId);

      // Then refresh in background if needed
      await _refreshContextInBackground(userId);

      await _updateLastPrewarmTime(userId);
      debugPrint('✅ [CALENDAR PREWARM] Startup prewarm completed');
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Startup prewarm error: $e');
    }
  }

  /// Quick sync for immediate PDA context refresh
  Future<void> quickSyncForPDA(String userId) async {
    try {
      debugPrint('⚡ [CALENDAR PREWARM] Quick sync for PDA context');

      // Get fresh data and cache it immediately
      await _refreshContextInBackground(userId);
      await _loadCachedContextForPDA(userId);

      debugPrint('✅ [CALENDAR PREWARM] Quick sync completed');
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Quick sync error: $e');
    }
  }

  /// Force refresh calendar data (bypass prewarm interval)
  Future<void> forceRefreshCalendarData(String userId) async {
    try {
      debugPrint(
        '🔄 [CALENDAR FORCE] Force refreshing calendar data for user: $userId',
      );

      // Clear existing cache first
      await _prefs.remove('${_contextCacheKey}_$userId');
      await _prefs.remove('${_lastPrewarmKey}_$userId');

      // Force refresh in background
      await _refreshContextInBackground(userId);
      await _loadCachedContextForPDA(userId);

      debugPrint('✅ [CALENDAR FORCE] Force refresh completed');
    } catch (e) {
      debugPrint('❌ [CALENDAR FORCE] Force refresh error: $e');
    }
  }

  /// Load cached context data for immediate PDA availability
  Future<void> _loadCachedContextForPDA(String userId) async {
    try {
      // Get cached upcoming events
      final upcomingEvents = await _cacheManager.getCachedUpcomingEvents(
        userId,
      );

      // Get cached recent events for correlation
      final recentEvents = await _cacheManager.getCachedRecentEvents(userId);

      // Get cached meeting events
      final meetingEvents = await _cacheManager.getCachedMeetingEvents(userId);

      // Build comprehensive context for PDA
      final contextData = await _buildPDAContext(
        userId,
        upcomingEvents ?? [],
        recentEvents ?? [],
        meetingEvents ?? [],
      );

      // Cache the processed context for PDA
      await _cachePDAContext(userId, contextData);

      debugPrint(
        '📋 [CALENDAR PREWARM] Loaded cached context: ${contextData.length} items',
      );
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Error loading cached context: $e');
    }
  }

  /// Refresh context data in background using Google Meet sync function
  Future<void> _refreshContextInBackground(String userId) async {
    try {
      // Check if user has connected Google account
      final account = await _supabaseDataSource.getGoogleMeetAccount(userId);
      if (account == null) {
        debugPrint('⚠️ [CALENDAR PREWARM] No Google account connected');
        return;
      }

      if (!account.isActive) {
        debugPrint('⚠️ [CALENDAR PREWARM] Google account is not active');
        return;
      }

      debugPrint(
        '🔄 [CALENDAR PREWARM] Triggering Google Meet sync (includes Calendar data)',
      );

      // Use the Google Meet sync function which already handles Calendar data
      final syncResult = await _supabaseDataSource.syncGoogleMeetData(userId);

      bool syncSuccess = false;
      if (syncResult['success'] == true) {
        syncSuccess = true;
        debugPrint('✅ [CALENDAR PREWARM] Sync completed successfully');
        debugPrint(
          '📊 [CALENDAR PREWARM] Sync result: ${syncResult['syncedData']}',
        );

        // Clear PDA context cache after successful sync to ensure fresh data
        await _clearPDAContextCache(userId);
        debugPrint(
          '🧹 [CALENDAR PREWARM] Cleared PDA context cache after sync',
        );
      } else {
        debugPrint(
          '⚠️ [CALENDAR PREWARM] Sync failed: ${syncResult['message']}',
        );
      }

      // Always attempt to get data from Supabase database and cache it,
      // regardless of whether the sync function succeeded or failed.
      // This ensures we always try to provide some context.
      try {
        debugPrint(
          '🔄 [CALENDAR PREWARM] Fetching fresh data from Supabase database',
        );

        final upcomingEvents = await _calendarSupabaseDataSource
            .getUpcomingEvents(userId, days: 60, limit: 50);

        final recentEvents = await _calendarSupabaseDataSource.getRecentEvents(
          userId,
          days: 30,
          limit: 50,
        );

        final meetingEvents = upcomingEvents
            .where((e) => e.hasMeetLink)
            .toList();

        if (upcomingEvents.isNotEmpty || recentEvents.isNotEmpty) {
          await _cacheManager.cacheUpcomingEvents(userId, upcomingEvents);
          await _cacheManager.cacheRecentEvents(userId, recentEvents);
          await _cacheManager.cacheMeetingEvents(userId, meetingEvents);

          // Update cache timestamp only if data was successfully fetched and cached
          await _cacheManager.updateLastSyncTime(userId);

          debugPrint(
            '✅ [CALENDAR PREWARM] Fetched and cached data from database: ${upcomingEvents.length} upcoming, ${recentEvents.length} recent, ${meetingEvents.length} meetings',
          );
        } else {
          debugPrint(
            'ℹ️ [CALENDAR PREWARM] No calendar data found in Supabase database after sync attempt.',
          );
        }
      } catch (dbError) {
        debugPrint(
          '❌ [CALENDAR PREWARM] Error fetching/caching from database: $dbError',
        );
      }
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Overall error refreshing context: $e');
    }
  }

  /// Build comprehensive PDA context from calendar data
  Future<Map<String, dynamic>> _buildPDAContext(
    String userId,
    List<GoogleCalendarEventModel> upcomingEvents,
    List<GoogleCalendarEventModel> recentEvents,
    List<GoogleCalendarEventModel> meetingEvents,
  ) async {
    final now = DateTime.now();

    // Debug logging to understand what data we have
    debugPrint('🔍 [CALENDAR DEBUG] Building PDA context for user: $userId');
    debugPrint('🔍 [CALENDAR DEBUG] Current time: $now');
    debugPrint(
      '🔍 [CALENDAR DEBUG] Raw upcoming events count: ${upcomingEvents.length}',
    );
    debugPrint(
      '🔍 [CALENDAR DEBUG] Recent events count: ${recentEvents.length}',
    );
    debugPrint(
      '🔍 [CALENDAR DEBUG] Meeting events count: ${meetingEvents.length}',
    );

    // Filter out past events from "upcoming" events (defensive programming)
    final actualUpcomingEvents = upcomingEvents.where((event) {
      final eventLocalTime = event.startTime.toLocal();
      final isActuallyUpcoming = eventLocalTime.isAfter(now);

      if (!isActuallyUpcoming) {
        debugPrint(
          '⚠️ [CALENDAR DEBUG] Filtering out past event from "upcoming": ${event.summary} at ${event.startTime} (UTC) / ${eventLocalTime} (Local) - Current: $now',
        );
      }

      return isActuallyUpcoming;
    }).toList();

    debugPrint(
      '🔍 [CALENDAR DEBUG] Filtered upcoming events count: ${actualUpcomingEvents.length}',
    );

    // Log all actual upcoming events for debugging
    for (int i = 0; i < actualUpcomingEvents.length && i < 5; i++) {
      final event = actualUpcomingEvents[i];
      debugPrint(
        '🔍 [CALENDAR DEBUG] Actual upcoming event $i: ${event.summary} at ${event.startTime} (UTC) / ${event.startTime.toLocal()} (Local)',
      );
    }

    // Also check recent events for today's completed meetings
    final todayCompletedEvents = recentEvents.where((event) {
      final eventDate = event.startTime.toLocal(); // Convert UTC to local time
      final isToday =
          eventDate.year == now.year &&
          eventDate.month == now.month &&
          eventDate.day == now.day;

      if (isToday) {
        debugPrint(
          '🔍 [CALENDAR DEBUG] Found today\'s completed event: ${event.summary} at ${event.startTime} (UTC) / ${eventDate} (Local)',
        );
      }

      return isToday;
    }).toList();

    // Categorize events for PDA with extended future coverage
    // Convert UTC times to local time (IST) for proper comparison
    final todayEvents = actualUpcomingEvents.where((event) {
      final eventDate = event.startTime.toLocal(); // Convert UTC to local time
      final isToday =
          eventDate.year == now.year &&
          eventDate.month == now.month &&
          eventDate.day == now.day;

      if (isToday) {
        debugPrint(
          '🔍 [CALENDAR DEBUG] Found today event: ${event.summary} at ${event.startTime} (UTC) / ${eventDate} (Local)',
        );
      }

      return isToday;
    }).toList();

    // Combine today's upcoming and completed events
    final allTodayEvents = [...todayEvents, ...todayCompletedEvents];

    debugPrint(
      '🔍 [CALENDAR DEBUG] Today events count: ${allTodayEvents.length} (${todayEvents.length} upcoming, ${todayCompletedEvents.length} completed)',
    );

    final tomorrowEvents = actualUpcomingEvents.where((event) {
      final tomorrow = now.add(const Duration(days: 1));
      final eventDate = event.startTime.toLocal(); // Convert UTC to local time
      return eventDate.year == tomorrow.year &&
          eventDate.month == tomorrow.month &&
          eventDate.day == tomorrow.day;
    }).toList();

    final thisWeekEvents = actualUpcomingEvents.where((event) {
      final weekFromNow = now.add(const Duration(days: 7));
      final eventLocalTime = event.startTime.toLocal();
      return eventLocalTime.isAfter(now) &&
          eventLocalTime.isBefore(weekFromNow);
    }).toList();

    final nextWeekEvents = actualUpcomingEvents.where((event) {
      final nextWeekStart = now.add(const Duration(days: 7));
      final nextWeekEnd = now.add(const Duration(days: 14));
      final eventLocalTime = event.startTime.toLocal();
      return eventLocalTime.isAfter(nextWeekStart) &&
          eventLocalTime.isBefore(nextWeekEnd);
    }).toList();

    final thisMonthEvents = actualUpcomingEvents.where((event) {
      final monthFromNow = now.add(const Duration(days: 30));
      final eventLocalTime = event.startTime.toLocal();
      return eventLocalTime.isAfter(now) &&
          eventLocalTime.isBefore(monthFromNow);
    }).toList();

    final futureEvents = actualUpcomingEvents.where((event) {
      final monthFromNow = now.add(const Duration(days: 30));
      final eventLocalTime = event.startTime.toLocal();
      return eventLocalTime.isAfter(monthFromNow);
    }).toList();

    // Get next immediate meeting
    final nextMeeting = actualUpcomingEvents.isNotEmpty
        ? actualUpcomingEvents.first
        : null;

    // Build context summary with current date/time
    final contextSummary = {
      'userId': userId,
      'lastUpdated': DateTime.now().toIso8601String(),
      'currentDateTime': {
        'timestamp': now.toIso8601String(),
        'date': '${now.day}/${now.month}/${now.year}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'dayOfWeek': _getDayOfWeek(now),
        'timezone': 'Asia/Calcutta (UTC+5:30)',
      },
      'summary': {
        'totalUpcoming': actualUpcomingEvents.length,
        'todayCount': allTodayEvents.length,
        'tomorrowCount': tomorrowEvents.length,
        'thisWeekCount': thisWeekEvents.length,
        'nextWeekCount': nextWeekEvents.length,
        'thisMonthCount': thisMonthEvents.length,
        'futureCount': futureEvents.length,
        'recentMeetingsCount': recentEvents.length,
      },
      'nextMeeting': nextMeeting != null
          ? {
              'title': nextMeeting.summary,
              'startTime': nextMeeting.startTime.toIso8601String(),
              'hasGoogleMeet': nextMeeting.hasMeetLink,
              'meetLink': nextMeeting.googleMeetLink,
              'timeUntil': _getTimeUntilMeeting(nextMeeting.startTime),
            }
          : null,
      'todayMeetings': allTodayEvents
          .map(
            (event) => {
              'title': event.summary,
              'startTime': event.startTime.toLocal().toIso8601String(),
              'endTime': event.endTime.toLocal().toIso8601String(),
              'hasGoogleMeet': event.hasMeetLink,
              'meetLink': event.googleMeetLink,
              'description': event.description,
              'location': event.location,
              'isCompleted': event.endTime.toLocal().isBefore(now),
            },
          )
          .toList(),
      'tomorrowMeetings': tomorrowEvents
          .map(
            (event) => {
              'title': event.summary,
              'startTime': event.startTime.toIso8601String(),
              'endTime': event.endTime.toIso8601String(),
              'hasGoogleMeet': event.hasMeetLink,
              'meetLink': event.googleMeetLink,
              'description': event.description,
            },
          )
          .toList(),
      'thisWeekMeetings': thisWeekEvents
          .take(15)
          .map(
            (event) => {
              'title': event.summary,
              'startTime': event.startTime.toIso8601String(),
              'endTime': event.endTime.toIso8601String(),
              'hasGoogleMeet': event.hasMeetLink,
              'meetLink': event.googleMeetLink,
              'dayOfWeek': _getDayOfWeek(event.startTime),
              'description': event.description,
            },
          )
          .toList(),
      'nextWeekMeetings': nextWeekEvents
          .take(15)
          .map(
            (event) => {
              'title': event.summary,
              'startTime': event.startTime.toIso8601String(),
              'endTime': event.endTime.toIso8601String(),
              'hasGoogleMeet': event.hasMeetLink,
              'meetLink': event.googleMeetLink,
              'dayOfWeek': _getDayOfWeek(event.startTime),
              'description': event.description,
            },
          )
          .toList(),
      'thisMonthMeetings': thisMonthEvents
          .take(20)
          .map(
            (event) => {
              'title': event.summary,
              'startTime': event.startTime.toIso8601String(),
              'endTime': event.endTime.toIso8601String(),
              'hasGoogleMeet': event.hasMeetLink,
              'meetLink': event.googleMeetLink,
              'dayOfWeek': _getDayOfWeek(event.startTime),
              'description': event.description,
            },
          )
          .toList(),
      'futureMeetings': futureEvents
          .take(10)
          .map(
            (event) => {
              'title': event.summary,
              'startTime': event.startTime.toIso8601String(),
              'endTime': event.endTime.toIso8601String(),
              'hasGoogleMeet': event.hasMeetLink,
              'meetLink': event.googleMeetLink,
              'dayOfWeek': _getDayOfWeek(event.startTime),
              'description': event.description,
            },
          )
          .toList(),
      'recentMeetings': recentEvents
          .take(10)
          .map(
            (event) => {
              'title': event.summary,
              'startTime': event.startTime.toIso8601String(),
              'endTime': event.endTime.toIso8601String(),
              'wasCompleted': event.isPast,
              'hasGoogleMeet': event.hasMeetLink,
              'description': event.description,
            },
          )
          .toList(),
    };

    return contextSummary;
  }

  /// Clear PDA context cache to force fresh data fetch
  Future<void> _clearPDAContextCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_contextCacheKey}_$userId');
      debugPrint(
        '🧹 [CALENDAR PDA] Cleared PDA context cache for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ [CALENDAR PDA] Error clearing PDA context cache: $e');
    }
  }

  /// Cache PDA context for immediate access
  Future<void> _cachePDAContext(
    String userId,
    Map<String, dynamic> context,
  ) async {
    try {
      final cacheKey = '${_contextCacheKey}_$userId';
      final contextJson = jsonEncode(context); // Proper JSON encoding

      await _prefs.setString(cacheKey, contextJson);
      debugPrint('💾 [CALENDAR PREWARM] Cached PDA context for user: $userId');
      debugPrint('📦 [CALENDAR PREWARM] Cached content: $contextJson');
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Error caching PDA context: $e');
    }
  }

  /// Get cached PDA context
  Future<Map<String, dynamic>?> getCachedPDAContext(String userId) async {
    try {
      final cacheKey = '${_contextCacheKey}_$userId';
      final cachedData = _prefs.getString(cacheKey);

      if (cachedData != null) {
        try {
          // Try to decode as proper JSON first
          return jsonDecode(cachedData) as Map<String, dynamic>;
        } catch (jsonError) {
          // If JSON decode fails, this might be legacy cache data (toString format)
          debugPrint(
            '⚠️ [CALENDAR PREWARM] Legacy cache format detected, clearing cache',
          );
          await _prefs.remove(cacheKey);
          return null;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Error getting cached PDA context: $e');
      return null;
    }
  }

  /// Clear PDA context cache to force fresh data fetch
  Future<void> clearPDAContextCachePublic(String userId) async {
    await _clearPDAContextCache(userId);
  }

  /// Check if we should prewarm (avoid too frequent calls)
  Future<bool> _shouldPrewarm(String userId) async {
    try {
      final lastPrewarmKey = '${_lastPrewarmKey}_$userId';
      final lastPrewarm = _prefs.getInt(lastPrewarmKey);

      if (lastPrewarm == null) return true;

      final lastPrewarmTime = DateTime.fromMillisecondsSinceEpoch(lastPrewarm);
      final timeSinceLastPrewarm = DateTime.now().difference(lastPrewarmTime);

      return timeSinceLastPrewarm > _prewarmInterval;
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Error checking prewarm timing: $e');
      return true; // Default to prewarming if we can't check
    }
  }

  /// Update last prewarm timestamp
  Future<void> _updateLastPrewarmTime(String userId) async {
    try {
      final lastPrewarmKey = '${_lastPrewarmKey}_$userId';
      await _prefs.setInt(
        lastPrewarmKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Error updating prewarm time: $e');
    }
  }

  /// Get human-readable time until meeting
  String _getTimeUntilMeeting(DateTime meetingTime) {
    final now = DateTime.now();
    final meetingLocalTime = meetingTime.toLocal();
    final difference = meetingLocalTime.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inDays} days';
    }
  }

  /// Get day of week for meeting
  String _getDayOfWeek(DateTime dateTime) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dateTime.weekday - 1];
  }

  /// Get Google Calendar context formatted for PDA responses
  Future<String> getGoogleCalendarContextForPda() async {
    try {
      // Get current user ID from SharedPreferences or another source
      // For now, we'll need to pass userId as parameter
      debugPrint('📅 [CALENDAR PDA] Getting calendar context for PDA');

      // Return empty for now - this method needs userId parameter
      return '';
    } catch (e) {
      debugPrint('❌ [CALENDAR PDA] Error getting calendar context: $e');
      return '';
    }
  }

  /// Get Google Calendar context formatted for PDA responses with userId
  Future<String> getGoogleCalendarContextForPdaWithUserId(String userId) async {
    try {
      debugPrint(
        '📅 [CALENDAR PDA] Getting calendar context for PDA user: $userId',
      );

      // Get cached context first
      final cachedContext = await getCachedPDAContext(userId);
      if (cachedContext != null) {
        debugPrint('📦 [CALENDAR PDA] Using cached context');
        return _formatCalendarContextForPDA(cachedContext);
      }

      debugPrint('📅 [CALENDAR PDA] No cached context, checking cache manager');

      // If no cache, try to build fresh context from cache manager
      final upcomingEvents = await _cacheManager.getCachedUpcomingEvents(
        userId,
      );
      final recentEvents = await _cacheManager.getCachedRecentEvents(userId);
      final meetingEvents = await _cacheManager.getCachedMeetingEvents(userId);

      // If cache manager has data, use it
      if (upcomingEvents != null ||
          recentEvents != null ||
          meetingEvents != null) {
        debugPrint('📦 [CALENDAR PDA] Using cache manager data');
        final contextData = await _buildPDAContext(
          userId,
          upcomingEvents ?? [],
          recentEvents ?? [],
          meetingEvents ?? [],
        );
        return _formatCalendarContextForPDA(contextData);
      }

      debugPrint('📅 [CALENDAR PDA] No cache data, checking Supabase database');

      // If no cache data, try to get from Supabase database
      final todayEvents = await _calendarSupabaseDataSource.getTodayEvents(
        userId,
      );
      final upcomingEventsFromDB = await _calendarSupabaseDataSource
          .getUpcomingEvents(userId, days: 60, limit: 50);
      final recentEventsFromDB = await _calendarSupabaseDataSource
          .getRecentEvents(userId, days: 30, limit: 50);

      debugPrint(
        '📅 [CALENDAR PDA] Found in database: ${todayEvents.length} today, ${upcomingEventsFromDB.length} upcoming, ${recentEventsFromDB.length} recent',
      );

      // If we have data from database, use it
      if (todayEvents.isNotEmpty ||
          upcomingEventsFromDB.isNotEmpty ||
          recentEventsFromDB.isNotEmpty) {
        debugPrint('💾 [CALENDAR PDA] Using database data');

        // Combine today events with upcoming events (avoiding duplicates)
        final allUpcomingEvents = <GoogleCalendarEventModel>[];
        allUpcomingEvents.addAll(todayEvents);

        // Add upcoming events that are not already in today events
        for (final event in upcomingEventsFromDB) {
          if (!allUpcomingEvents.any(
            (e) => e.googleEventId == event.googleEventId,
          )) {
            allUpcomingEvents.add(event);
          }
        }

        // Sort by start time
        allUpcomingEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

        final contextData = await _buildPDAContext(
          userId,
          allUpcomingEvents,
          recentEventsFromDB,
          allUpcomingEvents.where((e) => e.hasMeetLink).toList(),
        );

        // Cache the context for future use
        await _cachePDAContext(userId, contextData);

        return _formatCalendarContextForPDA(contextData);
      }

      debugPrint(
        '⚠️ [CALENDAR PDA] No calendar data found in cache or database',
      );
      return 'No calendar data available. Please connect your Google Calendar and sync your events.';
    } catch (e) {
      debugPrint('❌ [CALENDAR PDA] Error getting calendar context: $e');
      return 'Error retrieving calendar data. Please try again later.';
    }
  }

  /// Format calendar context for PDA AI responses
  String _formatCalendarContextForPDA(Map<String, dynamic> context) {
    if (context.isEmpty) return 'No calendar context available.';

    final currentDateTime =
        context['currentDateTime'] as Map<String, dynamic>? ?? {};
    final summary = context['summary'] as Map<String, dynamic>? ?? {};
    final nextMeeting = context['nextMeeting'] as Map<String, dynamic>?;
    final todayMeetings = context['todayMeetings'] as List<dynamic>? ?? [];
    final tomorrowMeetings =
        context['tomorrowMeetings'] as List<dynamic>? ?? [];
    final thisWeekMeetings =
        context['thisWeekMeetings'] as List<dynamic>? ?? [];
    final nextWeekMeetings =
        context['nextWeekMeetings'] as List<dynamic>? ?? [];
    final thisMonthMeetings =
        context['thisMonthMeetings'] as List<dynamic>? ?? [];
    final futureMeetings = context['futureMeetings'] as List<dynamic>? ?? [];
    final recentMeetings = context['recentMeetings'] as List<dynamic>? ?? [];

    String formattedContext =
        '''
📅 COMPREHENSIVE GOOGLE CALENDAR CONTEXT:

🕐 CURRENT DATE & TIME:
- Current Date: ${currentDateTime['date'] ?? 'Unknown'}
- Current Time: ${currentDateTime['time'] ?? 'Unknown'}
- Day of Week: ${currentDateTime['dayOfWeek'] ?? 'Unknown'}
- Timezone: ${currentDateTime['timezone'] ?? 'Unknown'}
- Timestamp: ${currentDateTime['timestamp'] ?? 'Unknown'}

📊 CALENDAR SUMMARY:
- Total upcoming events: ${summary['totalUpcoming'] ?? 0}
- Today's meetings: ${summary['todayCount'] ?? 0}
- Tomorrow's meetings: ${summary['tomorrowCount'] ?? 0}
- This week's meetings: ${summary['thisWeekCount'] ?? 0}
- Next week's meetings: ${summary['nextWeekCount'] ?? 0}
- This month's meetings: ${summary['thisMonthCount'] ?? 0}
- Future meetings (beyond 30 days): ${summary['futureCount'] ?? 0}
- Recent completed meetings: ${summary['recentMeetingsCount'] ?? 0}
''';

    // Add next meeting info
    if (nextMeeting != null) {
      formattedContext +=
          '''

🔔 NEXT IMMEDIATE MEETING:
- Title: ${nextMeeting['title'] ?? 'Untitled'}
- Time: ${_formatDateTime(nextMeeting['startTime'] as String?)}
- Time until meeting: ${nextMeeting['timeUntil'] ?? 'Unknown'}
- Has Google Meet: ${nextMeeting['hasGoogleMeet'] ?? false}
${nextMeeting['meetLink'] != null ? '- Meet Link: ${nextMeeting['meetLink']}' : ''}
''';
    }

    // Add today's meetings
    if (todayMeetings.isNotEmpty) {
      formattedContext += '\n📅 TODAY\'S MEETINGS:\n';
      for (final meeting in todayMeetings) {
        final isCompleted = meeting['isCompleted'] == true;
        formattedContext +=
            '''
- ${meeting['title'] ?? 'Untitled'} (${_formatTime(meeting['startTime'] as String?)} - ${_formatTime(meeting['endTime'] as String?)}) ${isCompleted ? '✅ Completed' : '⏳ Upcoming'}
  ${meeting['hasGoogleMeet'] == true ? '🎥 Has Google Meet' : '📞 No Google Meet'}
  ${meeting['description'] != null && (meeting['description'] as String).isNotEmpty ? 'Description: ${meeting['description']}' : ''}
  ${meeting['location'] != null && (meeting['location'] as String).isNotEmpty ? 'Location: ${meeting['location']}' : ''}
''';
      }
    }

    // Add tomorrow's meetings
    if (tomorrowMeetings.isNotEmpty) {
      formattedContext += '\n📅 TOMORROW\'S MEETINGS:\n';
      for (final meeting in tomorrowMeetings) {
        formattedContext +=
            '''
- ${meeting['title'] ?? 'Untitled'} (${_formatTime(meeting['startTime'] as String?)})
  ${meeting['hasGoogleMeet'] == true ? '🎥 Has Google Meet' : '📞 No Google Meet'}
  ${meeting['description'] != null && (meeting['description'] as String).isNotEmpty ? 'Description: ${meeting['description']}' : ''}
''';
      }
    }

    // Add this week's meetings
    if (thisWeekMeetings.isNotEmpty) {
      formattedContext += '\n📅 THIS WEEK\'S MEETINGS:\n';
      for (final meeting in thisWeekMeetings.take(10)) {
        formattedContext +=
            '''
- ${meeting['title'] ?? 'Untitled'} (${meeting['dayOfWeek']} ${_formatTime(meeting['startTime'] as String?)})
  ${meeting['hasGoogleMeet'] == true ? '🎥 Has Google Meet' : '📞 No Google Meet'}
  ${meeting['description'] != null && (meeting['description'] as String).isNotEmpty ? 'Description: ${meeting['description']}' : ''}
''';
      }
    }

    // Add next week's meetings
    if (nextWeekMeetings.isNotEmpty) {
      formattedContext += '\n📅 NEXT WEEK\'S MEETINGS:\n';
      for (final meeting in nextWeekMeetings.take(10)) {
        formattedContext +=
            '''
- ${meeting['title'] ?? 'Untitled'} (${meeting['dayOfWeek']} ${_formatTime(meeting['startTime'] as String?)})
  ${meeting['hasGoogleMeet'] == true ? '🎥 Has Google Meet' : '📞 No Google Meet'}
  ${meeting['description'] != null && (meeting['description'] as String).isNotEmpty ? 'Description: ${meeting['description']}' : ''}
''';
      }
    }

    // Add this month's meetings
    if (thisMonthMeetings.isNotEmpty) {
      formattedContext += '\n📅 THIS MONTH\'S MEETINGS:\n';
      for (final meeting in thisMonthMeetings.take(15)) {
        formattedContext +=
            '''
- ${meeting['title'] ?? 'Untitled'} (${meeting['dayOfWeek']} ${_formatDateTime(meeting['startTime'] as String?)})
  ${meeting['hasGoogleMeet'] == true ? '🎥 Has Google Meet' : '📞 No Google Meet'}
''';
      }
    }

    // Add future meetings (beyond 30 days)
    if (futureMeetings.isNotEmpty) {
      formattedContext += '\n📅 FUTURE MEETINGS (Beyond 30 days):\n';
      for (final meeting in futureMeetings.take(10)) {
        formattedContext +=
            '''
- ${meeting['title'] ?? 'Untitled'} (${_formatDateTime(meeting['startTime'] as String?)})
  ${meeting['hasGoogleMeet'] == true ? '🎥 Has Google Meet' : '📞 No Google Meet'}
''';
      }
    }

    // Add recent meetings
    if (recentMeetings.isNotEmpty) {
      formattedContext += '\n📅 RECENT COMPLETED MEETINGS:\n';
      for (final meeting in recentMeetings.take(5)) {
        formattedContext +=
            '''
- ${meeting['title'] ?? 'Untitled'} (${_formatDateTime(meeting['startTime'] as String?)})
  Status: ${meeting['wasCompleted'] == true ? '✅ Completed' : '⏳ Pending'}
  ${meeting['hasGoogleMeet'] == true ? '🎥 Had Google Meet' : '📞 No Google Meet'}
''';
      }
    }

    formattedContext += '''

🚀 ENHANCED CALENDAR CAPABILITIES:
- Answer questions about upcoming meetings and schedule across extended timeframes
- Provide detailed meeting information including Google Meet links and descriptions
- Help with scheduling conflicts and availability planning
- Remind about upcoming meetings and deadlines with precise timing
- Correlate calendar events with Google Meet data for comprehensive context
- Support queries about meetings today, tomorrow, this week, next week, this month, and future
- Provide current date/time context for accurate scheduling assistance
- Track recent meeting history for follow-up and context
''';
    debugPrint(
      '📝 [CALENDAR PDA] Formatted context for PDA: $formattedContext',
    );
    return formattedContext;
  }

  /// Format date time for display
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown time';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();

      if (dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day) {
        return 'Today ${_formatTime(dateTimeString)}';
      } else {
        return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTimeString)}';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  /// Format time for display (convert to local time)
  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown time';

    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return dateTimeString;
    }
  }

  /// Get prewarm statistics for debugging
  Future<Map<String, dynamic>> getPrewarmStats(String userId) async {
    try {
      final cacheStats = await _cacheManager.getCacheStats(userId);
      final lastPrewarm = await _getLastPrewarmTime(userId);

      return {
        'userId': userId,
        'lastPrewarmTime': lastPrewarm?.toIso8601String(),
        'cacheStats': cacheStats,
        'shouldPrewarm': await _shouldPrewarm(userId),
      };
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Error getting prewarm stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Get last prewarm time
  Future<DateTime?> _getLastPrewarmTime(String userId) async {
    try {
      final lastPrewarmKey = '${_lastPrewarmKey}_$userId';
      final timestamp = _prefs.getInt(lastPrewarmKey);

      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('❌ [CALENDAR PREWARM] Error getting last prewarm time: $e');
      return null;
    }
  }
}
