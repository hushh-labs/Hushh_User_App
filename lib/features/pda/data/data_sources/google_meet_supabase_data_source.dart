import '../models/google_meet_models/google_meet_account_model.dart';
import '../models/google_meet_models/google_meet_space_model.dart';
import '../models/google_meet_models/google_meet_conference_model.dart';
import '../models/google_meet_models/google_meet_participant_model.dart';
import '../models/google_meet_models/google_meet_recording_model.dart';
import '../models/google_meet_models/google_meet_transcript_model.dart';

abstract class GoogleMeetSupabaseDataSource {
  /// Account operations
  Future<GoogleMeetAccountModel?> getGoogleMeetAccount(String userId);
  Future<void> storeGoogleMeetAccount(GoogleMeetAccountModel account);
  Future<bool> isGoogleMeetConnected(String userId);
  Future<GoogleMeetAccountModel?> initiateGoogleMeetOAuth(String userId);
  Future<GoogleMeetAccountModel?> completeGoogleMeetOAuth(
    String userId,
    String authCode,
  );
  Future<void> disconnectGoogleMeet(String userId);

  /// Meeting spaces operations
  Future<List<GoogleMeetSpaceModel>> getMeetingSpaces(
    String userId, {
    int limit = 20,
  });
  Future<void> storeMeetingSpaces(
    String userId,
    List<GoogleMeetSpaceModel> spaces,
  );

  /// Conference operations
  Future<List<GoogleMeetConferenceModel>> getRecentConferences(
    String userId, {
    int limit = 30,
  });
  Future<void> storeConferences(
    String userId,
    List<GoogleMeetConferenceModel> conferences,
  );

  /// Participant operations
  Future<List<GoogleMeetParticipantModel>> getConferenceParticipants(
    String userId,
    String conferenceId,
  );
  Future<void> storeParticipants(
    String userId,
    List<GoogleMeetParticipantModel> participants,
  );

  /// Recording operations
  Future<List<GoogleMeetRecordingModel>> getRecordings(
    String userId, {
    int limit = 20,
  });
  Future<void> storeRecordings(
    String userId,
    List<GoogleMeetRecordingModel> recordings,
  );

  /// Transcript operations
  Future<List<GoogleMeetTranscriptModel>> getTranscripts(
    String userId, {
    int limit = 15,
  });
  Future<void> storeTranscripts(
    String userId,
    List<GoogleMeetTranscriptModel> transcripts,
  );

  /// Data synchronization
  Future<Map<String, dynamic>> syncGoogleMeetData(String userId);

  /// Analytics
  Future<Map<String, dynamic>> getBasicAnalytics(String userId);
}
