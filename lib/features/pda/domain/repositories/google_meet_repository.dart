import '../entities/google_meet_account.dart';
import '../entities/google_meet_space.dart';
import '../entities/google_meet_conference.dart';
import '../entities/google_meet_participant.dart';
import '../entities/google_meet_recording.dart';
import '../entities/google_meet_transcript.dart';

abstract class GoogleMeetRepository {
  /// Account management
  Future<GoogleMeetAccount?> getGoogleMeetAccount(String userId);
  Future<void> storeGoogleMeetAccount(GoogleMeetAccount account);
  Future<bool> isGoogleMeetConnected(String userId);
  Future<GoogleMeetAccount?> connectGoogleMeetAccount({
    required String userId,
    required String authCode,
  });
  Future<void> disconnectGoogleMeet(String userId);

  /// Meeting spaces
  Future<List<GoogleMeetSpace>> getMeetingSpaces(
    String userId, {
    int limit = 20,
  });
  Future<void> storeMeetingSpaces(String userId, List<GoogleMeetSpace> spaces);

  /// Conferences
  Future<List<GoogleMeetConference>> getRecentConferences(
    String userId, {
    int limit = 30,
  });
  Future<void> storeConferences(
    String userId,
    List<GoogleMeetConference> conferences,
  );

  /// Participants
  Future<List<GoogleMeetParticipant>> getConferenceParticipants(
    String userId,
    String conferenceId,
  );
  Future<void> storeParticipants(
    String userId,
    List<GoogleMeetParticipant> participants,
  );

  /// Recordings
  Future<List<GoogleMeetRecording>> getRecordings(
    String userId, {
    int limit = 20,
  });
  Future<void> storeRecordings(
    String userId,
    List<GoogleMeetRecording> recordings,
  );

  /// Transcripts
  Future<List<GoogleMeetTranscript>> getTranscripts(
    String userId, {
    int limit = 15,
  });
  Future<void> storeTranscripts(
    String userId,
    List<GoogleMeetTranscript> transcripts,
  );

  /// Data synchronization
  Future<void> syncGoogleMeetData(String userId);
  Future<Map<String, dynamic>> getBasicAnalytics(String userId);
}
