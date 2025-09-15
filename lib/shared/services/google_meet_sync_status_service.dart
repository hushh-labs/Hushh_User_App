import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Sync status for Google Meet
class GoogleMeetSyncStatus {
  final bool isActive;
  final bool isCompleted;
  final bool isFailed;
  final String? error;
  final DateTime? startTime;
  final DateTime? endTime;
  final int totalMeetings;
  final int processedMeetings;
  final List<GoogleMeetSyncLog> logs;

  const GoogleMeetSyncStatus({
    required this.isActive,
    required this.isCompleted,
    required this.isFailed,
    this.error,
    this.startTime,
    this.endTime,
    this.totalMeetings = 0,
    this.processedMeetings = 0,
    this.logs = const [],
  });

  GoogleMeetSyncStatus copyWith({
    bool? isActive,
    bool? isCompleted,
    bool? isFailed,
    String? error,
    DateTime? startTime,
    DateTime? endTime,
    int? totalMeetings,
    int? processedMeetings,
    List<GoogleMeetSyncLog>? logs,
  }) {
    return GoogleMeetSyncStatus(
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalMeetings: totalMeetings ?? this.totalMeetings,
      processedMeetings: processedMeetings ?? this.processedMeetings,
      logs: logs ?? this.logs,
    );
  }
}

/// Individual Google Meet sync log entry
class GoogleMeetSyncLog {
  final String message;
  final DateTime timestamp;
  final String level; // 'info', 'warning', 'error', 'success'

  const GoogleMeetSyncLog({
    required this.message,
    required this.timestamp,
    required this.level,
  });

  factory GoogleMeetSyncLog.fromMap(Map<String, dynamic> map) {
    return GoogleMeetSyncLog(
      message: map['message'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      level: map['level'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'level': level,
    };
  }
}

/// Service to track Google Meet sync status
class GoogleMeetSyncStatusService {
  static final GoogleMeetSyncStatusService _instance =
      GoogleMeetSyncStatusService._internal();
  factory GoogleMeetSyncStatusService() => _instance;
  GoogleMeetSyncStatusService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  final StreamController<GoogleMeetSyncStatus> _statusController =
      StreamController<GoogleMeetSyncStatus>.broadcast();

  GoogleMeetSyncStatus _currentStatus = const GoogleMeetSyncStatus(
    isActive: false,
    isCompleted: false,
    isFailed: false,
  );

  /// Stream of sync status updates
  Stream<GoogleMeetSyncStatus> get statusStream => _statusController.stream;

  /// Current sync status
  GoogleMeetSyncStatus get currentStatus => _currentStatus;

  /// Initialize the service and start listening to sync status
  Future<void> initialize() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ [GOOGLE MEET SYNC STATUS] No authenticated user');
        return;
      }

      debugPrint(
        '🔄 [GOOGLE MEET SYNC STATUS] Initializing service for user: ${user.uid}',
      );

      // Listen to the sync status document
      _statusSubscription = _firestore
          .collection('HushUsers')
          .doc(user.uid)
          .collection('sync_status')
          .doc('google_meet')
          .snapshots()
          .listen(
            _onStatusUpdate,
            onError: (error) {
              debugPrint('❌ [GOOGLE MEET SYNC STATUS] Stream error: $error');
            },
          );

      debugPrint(
        '✅ [GOOGLE MEET SYNC STATUS] Service initialized successfully',
      );
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SYNC STATUS] Error initializing: $e');
    }
  }

  /// Handle status document updates
  void _onStatusUpdate(DocumentSnapshot snapshot) {
    try {
      if (!snapshot.exists) {
        _currentStatus = const GoogleMeetSyncStatus(
          isActive: false,
          isCompleted: false,
          isFailed: false,
        );
        _statusController.add(_currentStatus);
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      // Parse logs
      final logsData = data['logs'] as List<dynamic>? ?? [];
      final logs = logsData.map((logData) {
        if (logData is Map<String, dynamic>) {
          return GoogleMeetSyncLog.fromMap(logData);
        }
        return GoogleMeetSyncLog(
          message: logData.toString(),
          timestamp: DateTime.now(),
          level: 'info',
        );
      }).toList();

      _currentStatus = GoogleMeetSyncStatus(
        isActive: data['isActive'] ?? false,
        isCompleted: data['isCompleted'] ?? false,
        isFailed: data['isFailed'] ?? false,
        error: data['error'],
        startTime: data['startTime'] != null
            ? DateTime.tryParse(data['startTime'])
            : null,
        endTime: data['endTime'] != null
            ? DateTime.tryParse(data['endTime'])
            : null,
        totalMeetings: data['totalMeetings'] ?? 0,
        processedMeetings: data['processedMeetings'] ?? 0,
        logs: logs,
      );

      debugPrint(
        '📝 [GOOGLE MEET SYNC STATUS] Updated logs: ${logs.length} entries',
      );
      _statusController.add(_currentStatus);
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SYNC STATUS] Error processing update: $e');
    }
  }

  /// Check if Google Meet data is ready in local storage
  Future<bool> isGoogleMeetDataReadyInLocalStorage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if we have Google Meet data in Firestore
      final meetingsSnapshot = await _firestore
          .collection('HushUsers')
          .doc(user.uid)
          .collection('sync_status')
          .doc('google_meet')
          .get();

      if (!meetingsSnapshot.exists) {
        debugPrint(
          '📧 [GOOGLE MEET SYNC STATUS] No Google Meet sync status found in local storage',
        );
        return false;
      }

      final data = meetingsSnapshot.data() as Map<String, dynamic>;
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
      final totalMeetings = metadata['totalMeetings'] as int? ?? 0;
      final isCompleted = data['isCompleted'] ?? false;
      final calendarDataReady = data['calendarDataReady'] ?? false;

      // Data is ready only when sync is completed, we have meetings, AND calendar context is verified ready
      final isReady = totalMeetings > 0 && isCompleted && calendarDataReady;
      debugPrint(
        '📧 [GOOGLE MEET SYNC STATUS] Data ready check: $isReady (meetings: $totalMeetings, completed: $isCompleted, calendarReady: $calendarDataReady)',
      );

      return isReady;
    } catch (e) {
      debugPrint(
        '❌ [GOOGLE MEET SYNC STATUS] Error checking data readiness: $e',
      );
      return false;
    }
  }

  /// Dispose the service
  void dispose() {
    _statusSubscription?.cancel();
    _statusController.close();
  }
}
