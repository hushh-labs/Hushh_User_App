import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hushh_user_app/core/config/supabase_init.dart';

import 'google_meet_supabase_data_source.dart';
import '../models/google_meet_models/google_meet_account_model.dart';
import '../models/google_meet_models/google_meet_space_model.dart';
import '../models/google_meet_models/google_meet_conference_model.dart';
import '../models/google_meet_models/google_meet_participant_model.dart';
import '../models/google_meet_models/google_meet_recording_model.dart';
import '../models/google_meet_models/google_meet_transcript_model.dart';

/// Custom exception for OAuth URL handling
class OAuthUrlException implements Exception {
  final String authUrl;

  const OAuthUrlException(this.authUrl);

  @override
  String toString() => 'OAuthUrlException: $authUrl';
}

class GoogleMeetSupabaseDataSourceImpl implements GoogleMeetSupabaseDataSource {
  final SupabaseClient _supabase;

  GoogleMeetSupabaseDataSourceImpl({SupabaseClient? supabase})
    : _supabase =
          supabase ?? (SupabaseInit.serviceClient ?? Supabase.instance.client);

  @override
  Future<GoogleMeetAccountModel?> getGoogleMeetAccount(String userId) async {
    try {
      debugPrint('🔍 [GOOGLE MEET SUPABASE] Getting account for user: $userId');

      final response = await _supabase
          .from('google_meet_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ [GOOGLE MEET SUPABASE] Account found');
        return GoogleMeetAccountModel.fromJson(response);
      }

      debugPrint('ℹ️ [GOOGLE MEET SUPABASE] No account found');
      return null;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error getting account: $e');
      throw Exception('Failed to get Google Meet account: $e');
    }
  }

  @override
  Future<void> storeGoogleMeetAccount(GoogleMeetAccountModel account) async {
    try {
      debugPrint(
        '💾 [GOOGLE MEET SUPABASE] Storing account for user: ${account.userId}',
      );

      await _supabase
          .from('google_meet_accounts')
          .upsert(account.toJson(), onConflict: 'user_id');

      debugPrint('✅ [GOOGLE MEET SUPABASE] Account stored successfully');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error storing account: $e');
      throw Exception('Failed to store Google Meet account: $e');
    }
  }

  @override
  Future<bool> isGoogleMeetConnected(String userId) async {
    try {
      final account = await getGoogleMeetAccount(userId);
      return account != null && account.isActive;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error checking connection: $e');
      return false;
    }
  }

  @override
  Future<GoogleMeetAccountModel?> initiateGoogleMeetOAuth(String userId) async {
    try {
      debugPrint(
        '🔗 [GOOGLE MEET SUPABASE] Initiating OAuth for user: $userId',
      );

      // Call the Supabase Edge Function to initiate OAuth
      final response = await _supabase.functions.invoke(
        'google-meet-sync',
        body: {'userId': userId, 'action': 'connect'},
      );

      if (response.data != null && response.data['success'] == true) {
        final authUrl = response.data['authUrl'] as String?;

        if (authUrl != null) {
          debugPrint('✅ [GOOGLE MEET SUPABASE] OAuth URL generated: $authUrl');

          // Import url_launcher to open the OAuth URL
          try {
            // Try to import and use url_launcher
            final Uri uri = Uri.parse(authUrl);

            // For now, we'll throw a custom exception with the URL
            // so the UI can handle opening it
            throw OAuthUrlException(authUrl);
          } catch (e) {
            if (e is OAuthUrlException) {
              rethrow;
            }
            debugPrint('❌ [GOOGLE MEET SUPABASE] Error opening URL: $e');
          }

          return null;
        }
      }

      throw Exception('Failed to initiate OAuth: ${response.data}');
    } catch (e) {
      if (e is OAuthUrlException) {
        rethrow;
      }
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error initiating OAuth: $e');
      throw Exception('Failed to initiate Google Meet OAuth: $e');
    }
  }

  @override
  Future<GoogleMeetAccountModel?> completeGoogleMeetOAuth(
    String userId,
    String authCode,
  ) async {
    try {
      debugPrint(
        '🔗 [GOOGLE MEET SUPABASE] Completing OAuth for user: $userId with auth code',
      );

      // Call the Supabase Edge Function to complete OAuth with the auth code
      final response = await _supabase.functions.invoke(
        'google-meet-sync',
        body: {'userId': userId, 'action': 'callback', 'code': authCode},
      );

      if (response.data != null && response.data['success'] == true) {
        final accountData = response.data['account'];

        if (accountData != null) {
          debugPrint('✅ [GOOGLE MEET SUPABASE] OAuth completed successfully');
          return GoogleMeetAccountModel.fromJson(accountData);
        }
      }

      throw Exception('Failed to complete OAuth: ${response.data}');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error completing OAuth: $e');
      throw Exception('Failed to complete Google Meet OAuth: $e');
    }
  }

  @override
  Future<void> disconnectGoogleMeet(String userId) async {
    try {
      debugPrint('🔌 [GOOGLE MEET SUPABASE] Disconnecting user: $userId');

      await _supabase
          .from('google_meet_accounts')
          .update({'is_active': false})
          .eq('user_id', userId);

      debugPrint('✅ [GOOGLE MEET SUPABASE] User disconnected successfully');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error disconnecting: $e');
      throw Exception('Failed to disconnect Google Meet: $e');
    }
  }

  @override
  Future<List<GoogleMeetSpaceModel>> getMeetingSpaces(
    String userId, {
    int limit = 20,
  }) async {
    try {
      debugPrint(
        '🔍 [GOOGLE MEET SUPABASE] Getting meeting spaces for user: $userId',
      );

      final response = await _supabase
          .from('google_meet_spaces')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final spaces = response
          .map<GoogleMeetSpaceModel>(
            (json) => GoogleMeetSpaceModel.fromJson(json),
          )
          .toList();

      debugPrint(
        '✅ [GOOGLE MEET SUPABASE] Found ${spaces.length} meeting spaces',
      );
      return spaces;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error getting meeting spaces: $e');
      throw Exception('Failed to get meeting spaces: $e');
    }
  }

  @override
  Future<void> storeMeetingSpaces(
    String userId,
    List<GoogleMeetSpaceModel> spaces,
  ) async {
    try {
      debugPrint(
        '💾 [GOOGLE MEET SUPABASE] Storing ${spaces.length} meeting spaces',
      );

      if (spaces.isEmpty) return;

      final spacesJson = spaces.map((space) => space.toJson()).toList();
      await _supabase.from('google_meet_spaces').upsert(spacesJson);

      debugPrint('✅ [GOOGLE MEET SUPABASE] Meeting spaces stored successfully');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error storing meeting spaces: $e');
      throw Exception('Failed to store meeting spaces: $e');
    }
  }

  @override
  Future<List<GoogleMeetConferenceModel>> getRecentConferences(
    String userId, {
    int limit = 30,
  }) async {
    try {
      debugPrint(
        '🔍 [GOOGLE MEET SUPABASE] Getting recent conferences for user: $userId',
      );

      final response = await _supabase
          .from('google_meet_conferences')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: false)
          .limit(limit);

      final conferences = response
          .map<GoogleMeetConferenceModel>(
            (json) => GoogleMeetConferenceModel.fromJson(json),
          )
          .toList();

      debugPrint(
        '✅ [GOOGLE MEET SUPABASE] Found ${conferences.length} conferences',
      );
      return conferences;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error getting conferences: $e');
      throw Exception('Failed to get conferences: $e');
    }
  }

  @override
  Future<void> storeConferences(
    String userId,
    List<GoogleMeetConferenceModel> conferences,
  ) async {
    try {
      debugPrint(
        '💾 [GOOGLE MEET SUPABASE] Storing ${conferences.length} conferences',
      );

      if (conferences.isEmpty) return;

      final conferencesJson = conferences.map((conf) => conf.toJson()).toList();
      await _supabase.from('google_meet_conferences').upsert(conferencesJson);

      debugPrint('✅ [GOOGLE MEET SUPABASE] Conferences stored successfully');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error storing conferences: $e');
      throw Exception('Failed to store conferences: $e');
    }
  }

  @override
  Future<List<GoogleMeetParticipantModel>> getConferenceParticipants(
    String userId,
    String conferenceId,
  ) async {
    try {
      debugPrint(
        '🔍 [GOOGLE MEET SUPABASE] Getting participants for conference: $conferenceId',
      );

      final response = await _supabase
          .from('google_meet_participants')
          .select()
          .eq('user_id', userId)
          .eq('conference_id', conferenceId)
          .order('join_time', ascending: true);

      final participants = response
          .map<GoogleMeetParticipantModel>(
            (json) => GoogleMeetParticipantModel.fromJson(json),
          )
          .toList();

      debugPrint(
        '✅ [GOOGLE MEET SUPABASE] Found ${participants.length} participants',
      );
      return participants;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error getting participants: $e');
      throw Exception('Failed to get participants: $e');
    }
  }

  @override
  Future<void> storeParticipants(
    String userId,
    List<GoogleMeetParticipantModel> participants,
  ) async {
    try {
      debugPrint(
        '💾 [GOOGLE MEET SUPABASE] Storing ${participants.length} participants',
      );

      if (participants.isEmpty) return;

      final participantsJson = participants.map((p) => p.toJson()).toList();
      await _supabase.from('google_meet_participants').upsert(participantsJson);

      debugPrint('✅ [GOOGLE MEET SUPABASE] Participants stored successfully');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error storing participants: $e');
      throw Exception('Failed to store participants: $e');
    }
  }

  @override
  Future<List<GoogleMeetRecordingModel>> getRecordings(
    String userId, {
    int limit = 20,
  }) async {
    try {
      debugPrint(
        '🔍 [GOOGLE MEET SUPABASE] Getting recordings for user: $userId',
      );

      final response = await _supabase
          .from('google_meet_recordings')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: false)
          .limit(limit);

      final recordings = response
          .map<GoogleMeetRecordingModel>(
            (json) => GoogleMeetRecordingModel.fromJson(json),
          )
          .toList();

      debugPrint(
        '✅ [GOOGLE MEET SUPABASE] Found ${recordings.length} recordings',
      );
      return recordings;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error getting recordings: $e');
      throw Exception('Failed to get recordings: $e');
    }
  }

  @override
  Future<void> storeRecordings(
    String userId,
    List<GoogleMeetRecordingModel> recordings,
  ) async {
    try {
      debugPrint(
        '💾 [GOOGLE MEET SUPABASE] Storing ${recordings.length} recordings',
      );

      if (recordings.isEmpty) return;

      final recordingsJson = recordings.map((r) => r.toJson()).toList();
      await _supabase.from('google_meet_recordings').upsert(recordingsJson);

      debugPrint('✅ [GOOGLE MEET SUPABASE] Recordings stored successfully');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error storing recordings: $e');
      throw Exception('Failed to store recordings: $e');
    }
  }

  @override
  Future<List<GoogleMeetTranscriptModel>> getTranscripts(
    String userId, {
    int limit = 15,
  }) async {
    try {
      debugPrint(
        '🔍 [GOOGLE MEET SUPABASE] Getting transcripts for user: $userId',
      );

      final response = await _supabase
          .from('google_meet_transcripts')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: false)
          .limit(limit);

      final transcripts = response
          .map<GoogleMeetTranscriptModel>(
            (json) => GoogleMeetTranscriptModel.fromJson(json),
          )
          .toList();

      debugPrint(
        '✅ [GOOGLE MEET SUPABASE] Found ${transcripts.length} transcripts',
      );
      return transcripts;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error getting transcripts: $e');
      throw Exception('Failed to get transcripts: $e');
    }
  }

  @override
  Future<void> storeTranscripts(
    String userId,
    List<GoogleMeetTranscriptModel> transcripts,
  ) async {
    try {
      debugPrint(
        '💾 [GOOGLE MEET SUPABASE] Storing ${transcripts.length} transcripts',
      );

      if (transcripts.isEmpty) return;

      final transcriptsJson = transcripts.map((t) => t.toJson()).toList();
      await _supabase.from('google_meet_transcripts').upsert(transcriptsJson);

      debugPrint('✅ [GOOGLE MEET SUPABASE] Transcripts stored successfully');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error storing transcripts: $e');
      throw Exception('Failed to store transcripts: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getBasicAnalytics(String userId) async {
    try {
      debugPrint(
        '📊 [GOOGLE MEET SUPABASE] Getting analytics for user: $userId',
      );

      // Get conference count and total duration
      final conferences = await getRecentConferences(userId, limit: 100);
      final recordings = await getRecordings(userId, limit: 50);
      final transcripts = await getTranscripts(userId, limit: 50);

      final totalMeetings = conferences.length;
      final totalDuration = conferences.fold<int>(
        0,
        (sum, conf) => sum + (conf.durationMinutes ?? 0),
      );
      final avgDuration = totalMeetings > 0 ? totalDuration / totalMeetings : 0;
      final totalParticipants = conferences.fold<int>(
        0,
        (sum, conf) => sum + conf.participantCount,
      );

      final analytics = {
        'totalMeetings': totalMeetings,
        'totalDurationMinutes': totalDuration,
        'averageDurationMinutes': avgDuration.round(),
        'totalParticipants': totalParticipants,
        'averageParticipants': totalMeetings > 0
            ? (totalParticipants / totalMeetings).round()
            : 0,
        'recordingsCount': recordings.length,
        'transcriptsCount': transcripts.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      debugPrint('✅ [GOOGLE MEET SUPABASE] Analytics generated');
      return analytics;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SUPABASE] Error getting analytics: $e');
      return {};
    }
  }
}
