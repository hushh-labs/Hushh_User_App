import 'package:flutter/foundation.dart';
import '../../domain/repositories/google_meet_repository.dart';
import '../../domain/entities/google_meet_account.dart';
import '../../domain/entities/google_meet_space.dart';
import '../../domain/entities/google_meet_conference.dart';
import '../../domain/entities/google_meet_participant.dart';
import '../../domain/entities/google_meet_recording.dart';
import '../../domain/entities/google_meet_transcript.dart';
import '../data_sources/google_meet_supabase_data_source.dart';
import '../models/google_meet_models/google_meet_account_model.dart';
import '../models/google_meet_models/google_meet_space_model.dart';
import '../models/google_meet_models/google_meet_conference_model.dart';
import '../models/google_meet_models/google_meet_participant_model.dart';
import '../models/google_meet_models/google_meet_recording_model.dart';
import '../models/google_meet_models/google_meet_transcript_model.dart';

class GoogleMeetRepositoryImpl implements GoogleMeetRepository {
  final GoogleMeetSupabaseDataSource _supabaseDataSource;

  GoogleMeetRepositoryImpl({
    required GoogleMeetSupabaseDataSource supabaseDataSource,
  }) : _supabaseDataSource = supabaseDataSource;

  @override
  Future<GoogleMeetAccount?> getGoogleMeetAccount(String userId) async {
    final accountModel = await _supabaseDataSource.getGoogleMeetAccount(userId);
    return accountModel?.toEntity();
  }

  @override
  Future<void> storeGoogleMeetAccount(GoogleMeetAccount account) async {
    final accountModel = GoogleMeetAccountModel.fromEntity(account);
    await _supabaseDataSource.storeGoogleMeetAccount(accountModel);
  }

  @override
  Future<bool> isGoogleMeetConnected(String userId) async {
    return await _supabaseDataSource.isGoogleMeetConnected(userId);
  }

  @override
  Future<GoogleMeetAccount?> connectGoogleMeetAccount({
    required String userId,
    required String authCode,
  }) async {
    try {
      debugPrint(
        '🔗 [GOOGLE MEET REPOSITORY] Completing OAuth for user: $userId',
      );

      // Call the Supabase data source to complete OAuth with the auth code
      final result = await _supabaseDataSource.completeGoogleMeetOAuth(
        userId,
        authCode,
      );

      if (result != null) {
        debugPrint('✅ [GOOGLE MEET REPOSITORY] OAuth completed successfully');
        return result.toEntity();
      }

      debugPrint('⚠️ [GOOGLE MEET REPOSITORY] No account returned from OAuth');
      return null;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET REPOSITORY] Error completing OAuth: $e');
      throw Exception('Failed to connect Google Meet account: $e');
    }
  }

  @override
  Future<void> disconnectGoogleMeet(String userId) async {
    await _supabaseDataSource.disconnectGoogleMeet(userId);
  }

  @override
  Future<List<GoogleMeetSpace>> getMeetingSpaces(
    String userId, {
    int limit = 20,
  }) async {
    final spaceModels = await _supabaseDataSource.getMeetingSpaces(
      userId,
      limit: limit,
    );
    return spaceModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> storeMeetingSpaces(
    String userId,
    List<GoogleMeetSpace> spaces,
  ) async {
    final spaceModels = spaces
        .map((space) => GoogleMeetSpaceModel.fromEntity(space))
        .toList();
    await _supabaseDataSource.storeMeetingSpaces(userId, spaceModels);
  }

  @override
  Future<List<GoogleMeetConference>> getRecentConferences(
    String userId, {
    int limit = 30,
  }) async {
    final conferenceModels = await _supabaseDataSource.getRecentConferences(
      userId,
      limit: limit,
    );
    return conferenceModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> storeConferences(
    String userId,
    List<GoogleMeetConference> conferences,
  ) async {
    final conferenceModels = conferences
        .map((conference) => GoogleMeetConferenceModel.fromEntity(conference))
        .toList();
    await _supabaseDataSource.storeConferences(userId, conferenceModels);
  }

  @override
  Future<List<GoogleMeetParticipant>> getConferenceParticipants(
    String userId,
    String conferenceId,
  ) async {
    final participantModels = await _supabaseDataSource
        .getConferenceParticipants(userId, conferenceId);
    return participantModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> storeParticipants(
    String userId,
    List<GoogleMeetParticipant> participants,
  ) async {
    final participantModels = participants
        .map(
          (participant) => GoogleMeetParticipantModel.fromEntity(participant),
        )
        .toList();
    await _supabaseDataSource.storeParticipants(userId, participantModels);
  }

  @override
  Future<List<GoogleMeetRecording>> getRecordings(
    String userId, {
    int limit = 20,
  }) async {
    final recordingModels = await _supabaseDataSource.getRecordings(
      userId,
      limit: limit,
    );
    return recordingModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> storeRecordings(
    String userId,
    List<GoogleMeetRecording> recordings,
  ) async {
    final recordingModels = recordings
        .map((recording) => GoogleMeetRecordingModel.fromEntity(recording))
        .toList();
    await _supabaseDataSource.storeRecordings(userId, recordingModels);
  }

  @override
  Future<List<GoogleMeetTranscript>> getTranscripts(
    String userId, {
    int limit = 15,
  }) async {
    final transcriptModels = await _supabaseDataSource.getTranscripts(
      userId,
      limit: limit,
    );
    return transcriptModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> storeTranscripts(
    String userId,
    List<GoogleMeetTranscript> transcripts,
  ) async {
    final transcriptModels = transcripts
        .map((transcript) => GoogleMeetTranscriptModel.fromEntity(transcript))
        .toList();
    await _supabaseDataSource.storeTranscripts(userId, transcriptModels);
  }

  @override
  Future<void> syncGoogleMeetData(String userId) async {
    // This would typically call the Google Meet API to fetch fresh data
    // For now, we'll implement a placeholder that could be extended
    // with actual API calls when Google Meet API integration is added

    // TODO: Implement Google Meet API calls here
    // 1. Fetch recent conferences from Google Meet API
    // 2. Fetch recordings and transcripts
    // 3. Store in Supabase via data source

    throw UnimplementedError(
      'Google Meet API integration not yet implemented. '
      'This method should fetch fresh data from Google Meet API and store in Supabase.',
    );
  }

  @override
  Future<Map<String, dynamic>> getBasicAnalytics(String userId) async {
    return await _supabaseDataSource.getBasicAnalytics(userId);
  }
}
