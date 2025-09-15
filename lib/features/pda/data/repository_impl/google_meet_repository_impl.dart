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
import '../services/google_calendar_context_prewarm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleMeetRepositoryImpl implements GoogleMeetRepository {
  final GoogleMeetSupabaseDataSource _supabaseDataSource;
  final GoogleCalendarContextPrewarmService? _calendarContextPrewarmService;

  GoogleMeetRepositoryImpl({
    required GoogleMeetSupabaseDataSource supabaseDataSource,
    GoogleCalendarContextPrewarmService? calendarContextPrewarmService,
  }) : _supabaseDataSource = supabaseDataSource,
       _calendarContextPrewarmService = calendarContextPrewarmService;

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

        // Automatically trigger data sync after successful OAuth
        try {
          debugPrint(
            '🔄 [GOOGLE MEET REPOSITORY] Starting automatic data sync...',
          );
          await syncGoogleMeetData(userId);
          debugPrint('✅ [GOOGLE MEET REPOSITORY] Automatic sync completed');

          // Wait for calendar context to be ready before completing OAuth
          debugPrint(
            '⏳ [GOOGLE MEET REPOSITORY] Waiting for calendar context to be ready for questions...',
          );
          final isCalendarReady = await _refreshCalendarContextAfterSync(
            userId,
          );

          if (isCalendarReady) {
            // Update sync status to mark as truly complete after calendar verification
            await _updateSyncStatusComplete(userId);
            debugPrint(
              '🎉 [GOOGLE MEET REPOSITORY] OAuth and calendar setup completed - calendar questions are now ready!',
            );
          } else {
            debugPrint(
              '⚠️ [GOOGLE MEET REPOSITORY] OAuth completed but calendar context not fully ready - may need manual refresh',
            );
          }
        } catch (syncError) {
          // Don't fail the OAuth if sync fails - just log the error
          debugPrint(
            '⚠️ [GOOGLE MEET REPOSITORY] Automatic sync failed: $syncError',
          );
          debugPrint(
            'ℹ️ [GOOGLE MEET REPOSITORY] OAuth still successful, sync can be retried later',
          );
        }

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
    try {
      debugPrint(
        '🔄 [GOOGLE MEET REPOSITORY] Starting data sync for user: $userId',
      );

      // Call the Supabase data source to trigger sync via edge function
      final result = await _supabaseDataSource.syncGoogleMeetData(userId);

      if (result['success'] == true) {
        debugPrint(
          '✅ [GOOGLE MEET REPOSITORY] Data sync completed successfully',
        );
        debugPrint(
          '📊 [GOOGLE MEET REPOSITORY] Sync result: ${result['syncedData']}',
        );

        // Wait for calendar context to be ready before completing sync
        debugPrint(
          '⏳ [GOOGLE MEET REPOSITORY] Waiting for calendar context to be ready for questions...',
        );

        // Retry calendar context verification with exponential backoff
        bool isCalendarReady = false;
        int retryCount = 0;
        const maxRetries = 5;

        while (!isCalendarReady && retryCount < maxRetries) {
          isCalendarReady = await _refreshCalendarContextAfterSync(userId);

          if (!isCalendarReady) {
            retryCount++;
            final waitTime = Duration(
              seconds: retryCount * 2,
            ); // 2, 4, 6, 8, 10 seconds
            debugPrint(
              '⏳ [GOOGLE MEET REPOSITORY] Calendar context not ready, retrying in ${waitTime.inSeconds}s (attempt $retryCount/$maxRetries)...',
            );
            await Future.delayed(waitTime);
          }
        }

        if (isCalendarReady) {
          // Update sync status to mark as truly complete after calendar verification
          await _updateSyncStatusComplete(userId);
          debugPrint(
            '🎉 [GOOGLE MEET REPOSITORY] Sync and calendar setup completed - calendar questions are now ready!',
          );
        } else {
          debugPrint(
            '❌ [GOOGLE MEET REPOSITORY] Calendar context still not ready after $maxRetries attempts',
          );
          throw Exception(
            'Calendar context not ready after sync completion. Please try refreshing or contact support.',
          );
        }
      } else {
        throw Exception('Sync failed: ${result['message']}');
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET REPOSITORY] Error syncing data: $e');
      throw Exception('Failed to sync Google Meet data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getBasicAnalytics(String userId) async {
    return await _supabaseDataSource.getBasicAnalytics(userId);
  }

  /// Update sync status to mark as truly complete after calendar verification
  /// This ensures the UI knows that calendar questions will work
  Future<void> _updateSyncStatusComplete(String userId) async {
    try {
      debugPrint(
        '🔄 [GOOGLE MEET REPOSITORY] Updating sync status to mark calendar data as ready...',
      );

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('HushUsers')
          .doc(userId)
          .collection('sync_status')
          .doc('google_meet')
          .set({
            'calendarDataReady': true,
            'calendarVerifiedAt': FieldValue.serverTimestamp(),
            'lastVerified': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      debugPrint(
        '✅ [GOOGLE MEET REPOSITORY] Sync status updated - UI will now show calendar data as ready',
      );
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET REPOSITORY] Error updating sync status: $e');
      // Don't throw - this is not critical to the functionality
    }
  }

  /// Refresh calendar context and verify it's ready for questions
  /// This ensures calendar data is immediately available for PDA questions
  /// Returns true only when calendar context is verified to be ready
  Future<bool> _refreshCalendarContextAfterSync(String userId) async {
    try {
      if (_calendarContextPrewarmService != null) {
        debugPrint(
          '⚡ [GOOGLE MEET REPOSITORY] Triggering immediate calendar context refresh after sync for user: $userId',
        );

        // Force refresh calendar context to make synced data immediately available
        await _calendarContextPrewarmService!.forceRefreshCalendarData(userId);

        // Verify that calendar context is actually ready by attempting to get it
        final calendarContext = await _calendarContextPrewarmService!
            .getGoogleCalendarContextForPdaWithUserId(userId);

        // Check if we have meaningful calendar data (not just empty or error messages)
        final hasValidCalendarData =
            calendarContext.isNotEmpty &&
            !calendarContext.contains('No calendar data available') &&
            !calendarContext.contains('Error retrieving calendar data') &&
            !calendarContext.contains('No calendar context available');

        if (hasValidCalendarData) {
          debugPrint(
            '✅ [GOOGLE MEET REPOSITORY] Calendar context verified ready - calendar questions will work immediately',
          );
          return true;
        } else {
          debugPrint(
            '⚠️ [GOOGLE MEET REPOSITORY] Calendar context refresh completed but no valid data found - retrying...',
          );

          // Wait a bit and try once more in case there's a small delay
          await Future.delayed(const Duration(seconds: 2));

          final retryContext = await _calendarContextPrewarmService!
              .getGoogleCalendarContextForPdaWithUserId(userId);

          final retryHasValidData =
              retryContext.isNotEmpty &&
              !retryContext.contains('No calendar data available') &&
              !retryContext.contains('Error retrieving calendar data') &&
              !retryContext.contains('No calendar context available');

          if (retryHasValidData) {
            debugPrint(
              '✅ [GOOGLE MEET REPOSITORY] Calendar context verified ready on retry - calendar questions will work immediately',
            );
            return true;
          } else {
            debugPrint(
              '⚠️ [GOOGLE MEET REPOSITORY] Calendar context still not ready after retry - may need manual refresh',
            );
            return false;
          }
        }
      } else {
        debugPrint(
          '⚠️ [GOOGLE MEET REPOSITORY] Calendar context prewarm service not available - calendar context may not be immediately updated',
        );
        return false;
      }
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET REPOSITORY] Error refreshing calendar context after sync: $e',
      );
      return false;
    }
  }
}
