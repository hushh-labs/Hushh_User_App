import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/google_meet_repository.dart';
import '../../domain/entities/google_meet_account.dart';
import '../../domain/entities/google_meet_conference.dart';
import '../../domain/entities/google_meet_recording.dart';
import '../../domain/entities/google_meet_transcript.dart';
import '../data_sources/pda_vertex_ai_data_source_impl.dart';
import 'google_meet_cache_manager.dart';

/// Service to pre-warm PDA with Google Meet context for faster responses
class GoogleMeetContextPrewarmService {
  static final GoogleMeetContextPrewarmService _instance =
      GoogleMeetContextPrewarmService._internal();
  factory GoogleMeetContextPrewarmService() => _instance;
  GoogleMeetContextPrewarmService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetIt _getIt = GetIt.instance;
  final GoogleMeetCacheManager _cacheManager = GoogleMeetCacheManager();

  // Cache for Google Meet context
  Map<String, dynamic> _googleMeetContextCache = {};

  // Stream controllers for real-time updates
  final StreamController<bool> _prewarmStatusController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _contextUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<bool> get prewarmStatusStream => _prewarmStatusController.stream;
  Stream<Map<String, dynamic>> get contextUpdateStream =>
      _contextUpdateController.stream;

  // Lazy getters for dependencies
  GoogleMeetRepository get _repository {
    try {
      return _getIt<GoogleMeetRepository>();
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET PREWARM] Repository not found in GetIt: $e');
      throw Exception(
        'GoogleMeetRepository not registered. Make sure GoogleMeetModule.register() is called.',
      );
    }
  }

  PdaVertexAiDataSourceImpl? get _pdaDataSource {
    try {
      return _getIt<PdaVertexAiDataSourceImpl>();
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET PREWARM] PDA data source not found: $e');
      return null;
    }
  }

  /// Check if Google Meet is connected for the current user
  Future<bool> isGoogleMeetConnected() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      return await _repository.isGoogleMeetConnected(user.uid);
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error checking connection status: $e',
      );
      return false;
    }
  }

  /// Pre-warm PDA with Google Meet context
  Future<void> prewarmGoogleMeetContext() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ [GOOGLE MEET PREWARM] No authenticated user');
        return;
      }

      debugPrint(
        '🚀 [GOOGLE MEET PREWARM] Starting Google Meet context pre-warming...',
      );
      _prewarmStatusController.add(true);

      // Check if Google Meet is connected
      final isConnected = await isGoogleMeetConnected();
      if (!isConnected) {
        debugPrint(
          'ℹ️ [GOOGLE MEET PREWARM] Google Meet not connected, skipping pre-warming',
        );
        _prewarmStatusController.add(false);
        return;
      }

      // Check if cache is still valid
      if (await _cacheManager.isCacheValid()) {
        debugPrint('📦 [GOOGLE MEET PREWARM] Using cached Google Meet context');
        final cachedContext = await _cacheManager.loadGoogleMeetContext();
        if (cachedContext.isNotEmpty) {
          _googleMeetContextCache = cachedContext;
          await _updatePdaWithGoogleMeetContext(cachedContext);
          _prewarmStatusController.add(false);
          return;
        }
      }

      // Fetch fresh Google Meet data
      final googleMeetContext = await _fetchGoogleMeetContext(user.uid);

      if (googleMeetContext.isNotEmpty) {
        // Cache the context
        _googleMeetContextCache = googleMeetContext;

        // Store context in local cache and Firestore
        await _cacheManager.storeGoogleMeetContext(googleMeetContext);
        await _cacheManager.storeGoogleMeetContextInFirestore(
          googleMeetContext,
        );

        // Update PDA with Google Meet context
        await _updatePdaWithGoogleMeetContext(googleMeetContext);

        debugPrint(
          '✅ [GOOGLE MEET PREWARM] Google Meet context pre-warmed successfully',
        );
        _contextUpdateController.add(googleMeetContext);
      } else {
        debugPrint('⚠️ [GOOGLE MEET PREWARM] No Google Meet context available');
      }

      _prewarmStatusController.add(false);
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error pre-warming Google Meet context: $e',
      );
      _prewarmStatusController.add(false);
    }
  }

  /// Fetch comprehensive Google Meet context
  Future<Map<String, dynamic>> _fetchGoogleMeetContext(String userId) async {
    try {
      debugPrint('📊 [GOOGLE MEET PREWARM] Fetching Google Meet context...');

      // Fetch Google Meet data in parallel for efficiency
      final futures = await Future.wait([
        _repository.getGoogleMeetAccount(userId),
        _repository.getRecentConferences(userId, limit: 30),
        _repository.getRecordings(userId, limit: 20),
        _repository.getTranscripts(userId, limit: 15),
        _repository.getBasicAnalytics(userId),
      ]);

      final account = futures[0] as GoogleMeetAccount?;
      final recentConferences = futures[1] as List<GoogleMeetConference>;
      final recordings = futures[2] as List<GoogleMeetRecording>;
      final transcripts = futures[3] as List<GoogleMeetTranscript>;
      final analytics = futures[4] as Map<String, dynamic>;

      // Create comprehensive context
      final context = {
        'account': _serializeGoogleMeetAccount(account),
        'recentConferences': recentConferences
            .map((conference) => _serializeGoogleMeetConference(conference))
            .toList(),
        'recordings': recordings
            .map((recording) => _serializeGoogleMeetRecording(recording))
            .toList(),
        'transcripts': transcripts
            .map((transcript) => _serializeGoogleMeetTranscript(transcript))
            .toList(),
        'analytics': analytics,
        'summary': _generateGoogleMeetSummary(
          account: account,
          recentConferences: recentConferences,
          recordings: recordings,
          transcripts: transcripts,
          analytics: analytics,
        ),
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint(
        '📊 [GOOGLE MEET PREWARM] Google Meet context fetched: ${recentConferences.length} conferences, ${recordings.length} recordings, ${transcripts.length} transcripts',
      );
      return context;
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error fetching Google Meet context: $e',
      );
      return {};
    }
  }

  /// Serialize Google Meet account to JSON
  Map<String, dynamic>? _serializeGoogleMeetAccount(
    GoogleMeetAccount? account,
  ) {
    if (account == null) return null;
    return {
      'userId': account.userId,
      'email': account.email,
      'displayName': account.displayName,
      'isActive': account.isActive,
      'connectedAt': account.connectedAt.toIso8601String(),
      'lastSyncedAt': account.lastSyncedAt?.toIso8601String(),
    };
  }

  /// Serialize Google Meet conference to JSON
  Map<String, dynamic> _serializeGoogleMeetConference(
    GoogleMeetConference conference,
  ) {
    return {
      'id': conference.id,
      'conferenceName': conference.conferenceName,
      'startTime': conference.startTime?.toIso8601String(),
      'endTime': conference.endTime?.toIso8601String(),
      'durationMinutes': conference.durationMinutes,
      'participantCount': conference.participantCount,
      'wasRecorded': conference.wasRecorded,
      'wasTranscribed': conference.wasTranscribed,
    };
  }

  /// Serialize Google Meet recording to JSON
  Map<String, dynamic> _serializeGoogleMeetRecording(
    GoogleMeetRecording recording,
  ) {
    return {
      'id': recording.id,
      'recordingName': recording.recordingName,
      'state': recording.state,
      'startTime': recording.startTime?.toIso8601String(),
      'endTime': recording.endTime?.toIso8601String(),
      'driveDestination': recording.driveDestination,
    };
  }

  /// Serialize Google Meet transcript to JSON
  Map<String, dynamic> _serializeGoogleMeetTranscript(
    GoogleMeetTranscript transcript,
  ) {
    return {
      'id': transcript.id,
      'transcriptName': transcript.transcriptName,
      'state': transcript.state,
      'startTime': transcript.startTime?.toIso8601String(),
      'endTime': transcript.endTime?.toIso8601String(),
      'driveDestination': transcript.driveDestination,
    };
  }

  /// Generate a comprehensive Google Meet summary for PDA context
  String _generateGoogleMeetSummary({
    GoogleMeetAccount? account,
    required List<GoogleMeetConference> recentConferences,
    required List<GoogleMeetRecording> recordings,
    required List<GoogleMeetTranscript> transcripts,
    required Map<String, dynamic> analytics,
  }) {
    final buffer = StringBuffer();

    // Account summary
    if (account != null) {
      buffer.writeln('Google Meet Account:');
      buffer.writeln('- Email: ${account.email}');
      buffer.writeln(
        '- Display Name: ${account.displayName ?? 'Not provided'}',
      );
      buffer.writeln('- Connected: ${account.connectedAt}');
      buffer.writeln('- Active: ${account.isActive}');
      if (account.lastSyncedAt != null) {
        buffer.writeln('- Last Sync: ${account.lastSyncedAt}');
      }
      buffer.writeln();
    }

    // Meeting statistics
    buffer.writeln('Meeting Statistics:');
    buffer.writeln('- Recent Conferences: ${recentConferences.length}');
    buffer.writeln('- Available Recordings: ${recordings.length}');
    buffer.writeln('- Available Transcripts: ${transcripts.length}');

    if (analytics.isNotEmpty) {
      buffer.writeln('- Total Meetings: ${analytics['totalMeetings'] ?? 0}');
      buffer.writeln(
        '- Total Duration: ${analytics['totalDurationMinutes'] ?? 0} minutes',
      );
      buffer.writeln(
        '- Average Duration: ${analytics['averageDurationMinutes'] ?? 0} minutes',
      );
      buffer.writeln(
        '- Average Participants: ${analytics['averageParticipants'] ?? 0}',
      );
    }
    buffer.writeln();

    // Recent conference activity
    if (recentConferences.isNotEmpty) {
      buffer.writeln('Recent Meeting Activity:');
      final recentCount = recentConferences.take(5).length;
      for (int i = 0; i < recentCount; i++) {
        final conference = recentConferences[i];
        final startTime = conference.startTime?.toString() ?? 'Unknown time';
        final duration = conference.durationMinutes ?? 0;
        final participants = conference.participantCount;
        final recorded = conference.wasRecorded ? 'Recorded' : 'Not recorded';
        buffer.writeln(
          '- $startTime: ${duration}min, $participants participants ($recorded)',
        );
      }
      buffer.writeln();
    }

    // Recordings summary
    if (recordings.isNotEmpty) {
      buffer.writeln('Available Recordings:');
      final recordingCount = recordings.take(3).length;
      for (int i = 0; i < recordingCount; i++) {
        final recording = recordings[i];
        final startTime = recording.startTime?.toString() ?? 'Unknown time';
        buffer.writeln(
          '- ${recording.recordingName}: $startTime (${recording.state})',
        );
      }
      buffer.writeln();
    }

    // Transcripts summary
    if (transcripts.isNotEmpty) {
      buffer.writeln('Available Transcripts:');
      final transcriptCount = transcripts.take(3).length;
      for (int i = 0; i < transcriptCount; i++) {
        final transcript = transcripts[i];
        final startTime = transcript.startTime?.toString() ?? 'Unknown time';
        buffer.writeln(
          '- ${transcript.transcriptName}: $startTime (${transcript.state})',
        );
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Update PDA with Google Meet context
  Future<void> _updatePdaWithGoogleMeetContext(
    Map<String, dynamic> context,
  ) async {
    try {
      final pdaDataSource = _pdaDataSource;
      if (pdaDataSource == null) {
        debugPrint('⚠️ [GOOGLE MEET PREWARM] PDA data source not available');
        return;
      }

      // Store Google Meet context in PDA's context cache
      await _storeGoogleMeetContextInPdaCache(context);

      debugPrint(
        '🧠 [GOOGLE MEET PREWARM] PDA updated with Google Meet context',
      );
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error updating PDA with Google Meet context: $e',
      );
    }
  }

  /// Store Google Meet context in PDA's internal cache
  Future<void> _storeGoogleMeetContextInPdaCache(
    Map<String, dynamic> context,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Store in Firestore under user's PDA context (using HushUsers collection)
      await _firestore
          .collection('HushUsers')
          .doc(user.uid)
          .collection('pda_context')
          .doc('google_meet')
          .set({
            'context': context,
            'lastUpdated': FieldValue.serverTimestamp(),
            'version': '1.0',
          });

      debugPrint(
        '💾 [GOOGLE MEET PREWARM] Google Meet context stored in PDA cache',
      );
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error storing Google Meet context in PDA cache: $e',
      );
    }
  }

  /// Load Google Meet context from cache
  Future<Map<String, dynamic>> loadGoogleMeetContextFromCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Check memory cache first
      if (await _cacheManager.isCacheValid()) {
        debugPrint('📦 [GOOGLE MEET PREWARM] Loading from memory cache');
        return _googleMeetContextCache;
      }

      // Load from local cache
      final localContext = await _cacheManager.loadGoogleMeetContext();
      if (localContext.isNotEmpty) {
        _googleMeetContextCache = localContext;
        debugPrint('📦 [GOOGLE MEET PREWARM] Loaded from local cache');
        return localContext;
      }

      // Load from Firestore cache
      final firestoreContext = await _cacheManager
          .loadGoogleMeetContextFromFirestore();
      if (firestoreContext.isNotEmpty) {
        _googleMeetContextCache = firestoreContext;
        debugPrint('📦 [GOOGLE MEET PREWARM] Loaded from Firestore cache');
        return firestoreContext;
      }

      debugPrint('📦 [GOOGLE MEET PREWARM] No cached context found');
      return {};
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error loading Google Meet context from cache: $e',
      );
      return {};
    }
  }

  /// Clear Google Meet context cache
  Future<void> clearGoogleMeetContextCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Clear memory cache
      _googleMeetContextCache.clear();

      // Clear all caches using cache manager
      await _cacheManager.clearAllCaches();

      // Clear PDA context cache
      await _firestore
          .collection('HushUsers')
          .doc(user.uid)
          .collection('pda_context')
          .doc('google_meet')
          .delete();

      debugPrint('🧹 [GOOGLE MEET PREWARM] Google Meet context cache cleared');
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error clearing Google Meet context cache: $e',
      );
    }
  }

  /// Get Google Meet context for PDA responses
  Future<String> getGoogleMeetContextForPda() async {
    try {
      // Try to get from cache first
      final context = await loadGoogleMeetContextFromCache();

      if (context.isNotEmpty && context['summary'] != null) {
        return context['summary'] as String;
      }

      // If no cache, try to pre-warm quickly
      final user = _auth.currentUser;
      if (user != null) {
        final quickContext = await _fetchGoogleMeetContext(user.uid);
        if (quickContext.isNotEmpty && quickContext['summary'] != null) {
          return quickContext['summary'] as String;
        }
      }

      return 'Google Meet context not available.';
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error getting Google Meet context for PDA: $e',
      );
      return 'Google Meet context not available.';
    }
  }

  /// Start monitoring Google Meet connection changes
  void startGoogleMeetMonitoring() {
    debugPrint('👁️ [GOOGLE MEET PREWARM] Starting Google Meet monitoring...');

    // Monitor authentication state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in, check Google Meet connection and pre-warm if needed
        _checkAndPrewarmOnAuthChange();
      } else {
        // User signed out, clear cache
        clearGoogleMeetContextCache();
      }
    });
  }

  /// Check and pre-warm Google Meet context on authentication changes
  Future<void> _checkAndPrewarmOnAuthChange() async {
    try {
      final isConnected = await isGoogleMeetConnected();
      if (isConnected) {
        debugPrint(
          '🔄 [GOOGLE MEET PREWARM] Google Meet connected, pre-warming context...',
        );
        await prewarmGoogleMeetContext();
      }
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET PREWARM] Error checking Google Meet on auth change: $e',
      );
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return await _cacheManager.getCacheStats();
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET PREWARM] Error getting cache stats: $e');
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    _prewarmStatusController.close();
    _contextUpdateController.close();
  }
}
