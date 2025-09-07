import '../models/google_meet_models/google_meet_account_model.dart';
import '../models/google_meet_models/google_meet_space_model.dart';
import '../models/google_meet_models/google_meet_conference_model.dart';
import '../models/google_meet_models/google_meet_participant_model.dart';
import '../models/google_meet_models/google_meet_recording_model.dart';
import '../models/google_meet_models/google_meet_transcript_model.dart';

abstract class GoogleMeetApiDataSource {
  /// Authentication
  Future<Map<String, dynamic>> authenticateWithGoogle();
  Future<void> refreshAccessToken(String refreshToken);
  Future<bool> isTokenValid(String accessToken);

  /// Account operations
  Future<GoogleMeetAccountModel> getUserProfile(String accessToken);

  /// Meeting spaces operations
  Future<List<GoogleMeetSpaceModel>> fetchMeetingSpaces(
    String accessToken, {
    int limit = 20,
  });
  Future<GoogleMeetSpaceModel> createMeetingSpace(
    String accessToken,
    Map<String, dynamic> spaceConfig,
  );

  /// Conference operations
  Future<List<GoogleMeetConferenceModel>> fetchRecentConferences(
    String accessToken, {
    int limit = 30,
  });
  Future<GoogleMeetConferenceModel> getConference(
    String accessToken,
    String conferenceId,
  );

  /// Participant operations
  Future<List<GoogleMeetParticipantModel>> fetchConferenceParticipants(
    String accessToken,
    String conferenceId,
  );

  /// Recording operations
  Future<List<GoogleMeetRecordingModel>> fetchRecordings(
    String accessToken, {
    int limit = 20,
  });
  Future<GoogleMeetRecordingModel> getRecording(
    String accessToken,
    String recordingId,
  );

  /// Transcript operations
  Future<List<GoogleMeetTranscriptModel>> fetchTranscripts(
    String accessToken, {
    int limit = 15,
  });
  Future<GoogleMeetTranscriptModel> getTranscript(
    String accessToken,
    String transcriptId,
  );
}
