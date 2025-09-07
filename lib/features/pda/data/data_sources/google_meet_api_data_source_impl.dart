import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'google_meet_api_data_source.dart';
import '../models/google_meet_models/google_meet_account_model.dart';
import '../models/google_meet_models/google_meet_space_model.dart';
import '../models/google_meet_models/google_meet_conference_model.dart';
import '../models/google_meet_models/google_meet_participant_model.dart';
import '../models/google_meet_models/google_meet_recording_model.dart';
import '../models/google_meet_models/google_meet_transcript_model.dart';

class GoogleMeetApiDataSourceImpl implements GoogleMeetApiDataSource {
  static const String _baseUrl = 'https://meet.googleapis.com/v2';
  final http.Client _httpClient;

  GoogleMeetApiDataSourceImpl({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  Future<Map<String, dynamic>> authenticateWithGoogle() async {
    // This would typically use Google OAuth2 flow
    // For now, return a placeholder that indicates OAuth is needed
    throw UnimplementedError(
      'Google OAuth2 authentication needs to be implemented. '
      'This should use google_sign_in package or similar OAuth flow.',
    );
  }

  @override
  Future<void> refreshAccessToken(String refreshToken) async {
    try {
      debugPrint('🔄 [GOOGLE MEET API] Refreshing access token...');

      // This would call Google's token refresh endpoint
      throw UnimplementedError(
        'Token refresh needs to be implemented with Google OAuth2 endpoints.',
      );
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error refreshing token: $e');
      throw Exception('Failed to refresh access token: $e');
    }
  }

  @override
  Future<bool> isTokenValid(String accessToken) async {
    try {
      // Test token validity by making a simple API call
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/conferenceRecords'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error validating token: $e');
      return false;
    }
  }

  @override
  Future<GoogleMeetAccountModel> getUserProfile(String accessToken) async {
    try {
      debugPrint('👤 [GOOGLE MEET API] Fetching user profile...');

      // This would typically call Google People API or similar
      // For now, return a placeholder
      throw UnimplementedError(
        'User profile fetching needs to be implemented. '
        'This should call Google People API or similar to get user info.',
      );
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<List<GoogleMeetSpaceModel>> fetchMeetingSpaces(
    String accessToken, {
    int limit = 20,
  }) async {
    try {
      debugPrint('🏢 [GOOGLE MEET API] Fetching meeting spaces...');

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/spaces?pageSize=$limit'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final spaces = data['spaces'] as List<dynamic>? ?? [];

        return spaces
            .map((space) => GoogleMeetSpaceModel.fromJson(space))
            .toList();
      } else {
        throw Exception(
          'API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching meeting spaces: $e');
      throw Exception('Failed to fetch meeting spaces: $e');
    }
  }

  @override
  Future<GoogleMeetSpaceModel> createMeetingSpace(
    String accessToken,
    Map<String, dynamic> spaceConfig,
  ) async {
    try {
      debugPrint('➕ [GOOGLE MEET API] Creating meeting space...');

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/spaces'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(spaceConfig),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GoogleMeetSpaceModel.fromJson(data);
      } else {
        throw Exception(
          'API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error creating meeting space: $e');
      throw Exception('Failed to create meeting space: $e');
    }
  }

  @override
  Future<List<GoogleMeetConferenceModel>> fetchRecentConferences(
    String accessToken, {
    int limit = 30,
  }) async {
    try {
      debugPrint('📊 [GOOGLE MEET API] Fetching recent conferences...');

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/conferenceRecords?pageSize=$limit'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final conferences = data['conferenceRecords'] as List<dynamic>? ?? [];

        return conferences
            .map((conference) => GoogleMeetConferenceModel.fromJson(conference))
            .toList();
      } else {
        throw Exception(
          'API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching conferences: $e');
      throw Exception('Failed to fetch conferences: $e');
    }
  }

  @override
  Future<GoogleMeetConferenceModel> getConference(
    String accessToken,
    String conferenceId,
  ) async {
    try {
      debugPrint('📊 [GOOGLE MEET API] Fetching conference: $conferenceId');

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/conferenceRecords/$conferenceId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GoogleMeetConferenceModel.fromJson(data);
      } else {
        throw Exception(
          'API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching conference: $e');
      throw Exception('Failed to fetch conference: $e');
    }
  }

  @override
  Future<List<GoogleMeetParticipantModel>> fetchConferenceParticipants(
    String accessToken,
    String conferenceId,
  ) async {
    try {
      debugPrint(
        '👥 [GOOGLE MEET API] Fetching participants for: $conferenceId',
      );

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/conferenceRecords/$conferenceId/participants'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final participants = data['participants'] as List<dynamic>? ?? [];

        return participants
            .map(
              (participant) => GoogleMeetParticipantModel.fromJson(participant),
            )
            .toList();
      } else {
        throw Exception(
          'API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching participants: $e');
      throw Exception('Failed to fetch participants: $e');
    }
  }

  @override
  Future<List<GoogleMeetRecordingModel>> fetchRecordings(
    String accessToken, {
    int limit = 20,
  }) async {
    try {
      debugPrint('🎥 [GOOGLE MEET API] Fetching recordings...');

      // Note: This would need to iterate through conferences to get recordings
      // as recordings are nested under conference records
      final conferences = await fetchRecentConferences(
        accessToken,
        limit: limit,
      );
      final List<GoogleMeetRecordingModel> allRecordings = [];

      for (final conference in conferences) {
        try {
          final response = await _httpClient.get(
            Uri.parse(
              '$_baseUrl/conferenceRecords/${conference.id}/recordings',
            ),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final recordings = data['recordings'] as List<dynamic>? ?? [];

            allRecordings.addAll(
              recordings.map(
                (recording) => GoogleMeetRecordingModel.fromJson(recording),
              ),
            );
          }
        } catch (e) {
          debugPrint(
            '⚠️ [GOOGLE MEET API] Error fetching recordings for conference ${conference.id}: $e',
          );
          // Continue with other conferences
        }
      }

      return allRecordings.take(limit).toList();
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching recordings: $e');
      throw Exception('Failed to fetch recordings: $e');
    }
  }

  @override
  Future<GoogleMeetRecordingModel> getRecording(
    String accessToken,
    String recordingId,
  ) async {
    try {
      debugPrint('🎥 [GOOGLE MEET API] Fetching recording: $recordingId');

      // Note: Recording ID format is typically conferenceRecords/{conferenceId}/recordings/{recordingId}
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/$recordingId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GoogleMeetRecordingModel.fromJson(data);
      } else {
        throw Exception(
          'API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching recording: $e');
      throw Exception('Failed to fetch recording: $e');
    }
  }

  @override
  Future<List<GoogleMeetTranscriptModel>> fetchTranscripts(
    String accessToken, {
    int limit = 15,
  }) async {
    try {
      debugPrint('📝 [GOOGLE MEET API] Fetching transcripts...');

      // Note: Similar to recordings, transcripts are nested under conference records
      final conferences = await fetchRecentConferences(
        accessToken,
        limit: limit,
      );
      final List<GoogleMeetTranscriptModel> allTranscripts = [];

      for (final conference in conferences) {
        try {
          final response = await _httpClient.get(
            Uri.parse(
              '$_baseUrl/conferenceRecords/${conference.id}/transcripts',
            ),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final transcripts = data['transcripts'] as List<dynamic>? ?? [];

            allTranscripts.addAll(
              transcripts.map(
                (transcript) => GoogleMeetTranscriptModel.fromJson(transcript),
              ),
            );
          }
        } catch (e) {
          debugPrint(
            '⚠️ [GOOGLE MEET API] Error fetching transcripts for conference ${conference.id}: $e',
          );
          // Continue with other conferences
        }
      }

      return allTranscripts.take(limit).toList();
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching transcripts: $e');
      throw Exception('Failed to fetch transcripts: $e');
    }
  }

  @override
  Future<GoogleMeetTranscriptModel> getTranscript(
    String accessToken,
    String transcriptId,
  ) async {
    try {
      debugPrint('📝 [GOOGLE MEET API] Fetching transcript: $transcriptId');

      // Note: Transcript ID format is typically conferenceRecords/{conferenceId}/transcripts/{transcriptId}
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/$transcriptId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GoogleMeetTranscriptModel.fromJson(data);
      } else {
        throw Exception(
          'API returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET API] Error fetching transcript: $e');
      throw Exception('Failed to fetch transcript: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
