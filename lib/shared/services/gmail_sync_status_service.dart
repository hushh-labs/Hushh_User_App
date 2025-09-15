import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Represents different stages of Gmail sync
enum GmailSyncStage {
  connecting,
  authenticating,
  fetchingThreads,
  fetchingMessages,
  processingContent,
  storingLocally,
  indexingData,
  updatingContext,
  completed,
  failed,
}

/// Extension to provide display names for Gmail sync stages
extension GmailSyncStageExtension on GmailSyncStage {
  String get stageDisplayName {
    switch (this) {
      case GmailSyncStage.connecting:
        return 'Connecting';
      case GmailSyncStage.authenticating:
        return 'Authenticating';
      case GmailSyncStage.fetchingThreads:
        return 'Fetching Threads';
      case GmailSyncStage.fetchingMessages:
        return 'Downloading Messages';
      case GmailSyncStage.processingContent:
        return 'Processing Content';
      case GmailSyncStage.storingLocally:
        return 'Storing Locally';
      case GmailSyncStage.indexingData:
        return 'Indexing Data';
      case GmailSyncStage.updatingContext:
        return 'Updating Context';
      case GmailSyncStage.completed:
        return 'Completed';
      case GmailSyncStage.failed:
        return 'Failed';
    }
  }
}

/// Represents a Gmail sync log entry
class GmailSyncLog {
  final String id;
  final DateTime timestamp;
  final GmailSyncStage stage;
  final String message;
  final Map<String, dynamic>? metadata;
  final bool isError;
  final double? progress; // 0.0 to 1.0

  const GmailSyncLog({
    required this.id,
    required this.timestamp,
    required this.stage,
    required this.message,
    this.metadata,
    this.isError = false,
    this.progress,
  });

  GmailSyncLog copyWith({
    String? id,
    DateTime? timestamp,
    GmailSyncStage? stage,
    String? message,
    Map<String, dynamic>? metadata,
    bool? isError,
    double? progress,
  }) {
    return GmailSyncLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      stage: stage ?? this.stage,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      isError: isError ?? this.isError,
      progress: progress ?? this.progress,
    );
  }

  String get displayMessage {
    switch (stage) {
      case GmailSyncStage.connecting:
        return 'Connecting to Gmail...';
      case GmailSyncStage.authenticating:
        return 'Authenticating with Google...';
      case GmailSyncStage.fetchingThreads:
        final count = metadata?['threadCount'] ?? 0;
        return count > 0
            ? 'Fetching email threads ($count found)...'
            : 'Scanning for email threads...';
      case GmailSyncStage.fetchingMessages:
        final current = metadata?['currentMessage'] ?? 0;
        final total = metadata?['totalMessages'] ?? 0;
        return total > 0
            ? 'Downloading messages ($current/$total)...'
            : 'Downloading email messages...';
      case GmailSyncStage.processingContent:
        return 'Processing email content...';
      case GmailSyncStage.storingLocally:
        final count = metadata?['storedCount'] ?? 0;
        return count > 0
            ? 'Storing emails locally ($count processed)...'
            : 'Storing emails locally...';
      case GmailSyncStage.indexingData:
        return 'Indexing email data for search...';
      case GmailSyncStage.updatingContext:
        return 'Preparing PDA context...';
      case GmailSyncStage.completed:
        final total = metadata?['totalProcessed'] ?? 0;
        return total > 0
            ? 'Gmail sync completed! Processed $total emails.'
            : 'Gmail sync completed successfully!';
      case GmailSyncStage.failed:
        return isError ? message : 'Gmail sync failed. Please try again.';
    }
  }

  String get stageDisplayName {
    switch (stage) {
      case GmailSyncStage.connecting:
        return 'Connecting';
      case GmailSyncStage.authenticating:
        return 'Authenticating';
      case GmailSyncStage.fetchingThreads:
        return 'Fetching Threads';
      case GmailSyncStage.fetchingMessages:
        return 'Downloading Messages';
      case GmailSyncStage.processingContent:
        return 'Processing Content';
      case GmailSyncStage.storingLocally:
        return 'Storing Locally';
      case GmailSyncStage.indexingData:
        return 'Indexing Data';
      case GmailSyncStage.updatingContext:
        return 'Updating Context';
      case GmailSyncStage.completed:
        return 'Completed';
      case GmailSyncStage.failed:
        return 'Failed';
    }
  }
}

/// Represents the overall Gmail sync status
class GmailSyncStatus {
  final bool isActive;
  final GmailSyncStage currentStage;
  final double overallProgress; // 0.0 to 1.0
  final List<GmailSyncLog> recentLogs;
  final DateTime? startedAt;
  final DateTime? lastUpdateAt;
  final Map<String, dynamic>? metadata;
  final bool hasError;

  const GmailSyncStatus({
    required this.isActive,
    required this.currentStage,
    required this.overallProgress,
    required this.recentLogs,
    this.startedAt,
    this.lastUpdateAt,
    this.metadata,
    this.hasError = false,
  });

  bool get isCompleted => currentStage == GmailSyncStage.completed;
  bool get isFailed => currentStage == GmailSyncStage.failed || hasError;

  GmailSyncLog? get latestLog => recentLogs.isNotEmpty ? recentLogs.last : null;

  GmailSyncStatus copyWith({
    bool? isActive,
    GmailSyncStage? currentStage,
    double? overallProgress,
    List<GmailSyncLog>? recentLogs,
    DateTime? startedAt,
    DateTime? lastUpdateAt,
    Map<String, dynamic>? metadata,
    bool? hasError,
  }) {
    return GmailSyncStatus(
      isActive: isActive ?? this.isActive,
      currentStage: currentStage ?? this.currentStage,
      overallProgress: overallProgress ?? this.overallProgress,
      recentLogs: recentLogs ?? this.recentLogs,
      startedAt: startedAt ?? this.startedAt,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      metadata: metadata ?? this.metadata,
      hasError: hasError ?? this.hasError,
    );
  }
}

/// Service to track and stream Gmail sync status and logs
class GmailSyncStatusService {
  static final GmailSyncStatusService _instance =
      GmailSyncStatusService._internal();
  factory GmailSyncStatusService() => _instance;
  GmailSyncStatusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controllers
  final StreamController<GmailSyncStatus> _statusController =
      StreamController<GmailSyncStatus>.broadcast();
  final StreamController<GmailSyncLog> _logController =
      StreamController<GmailSyncLog>.broadcast();

  // Current state
  GmailSyncStatus _currentStatus = const GmailSyncStatus(
    isActive: false,
    currentStage: GmailSyncStage.completed,
    overallProgress: 0.0,
    recentLogs: [],
  );

  // Firestore listeners
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  StreamSubscription<QuerySnapshot>? _logsSubscription;

  /// Stream of Gmail sync status updates
  Stream<GmailSyncStatus> get statusStream => _statusController.stream;

  /// Stream of individual Gmail sync logs
  Stream<GmailSyncLog> get logStream => _logController.stream;

  /// Current Gmail sync status
  GmailSyncStatus get currentStatus => _currentStatus;

  /// Initialize the service and start listening to Firestore
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint(
      '🔄 [GMAIL SYNC STATUS] Initializing service for user: ${user.uid}',
    );

    // Listen to sync status document
    _statusSubscription = _firestore
        .collection('gmail_sync_status')
        .doc(user.uid)
        .snapshots()
        .listen(_handleStatusUpdate);

    // Listen to sync logs collection
    _logsSubscription = _firestore
        .collection('gmail_sync_status')
        .doc(user.uid)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen(_handleLogsUpdate);
  }

  /// Handle sync status document updates
  void _handleStatusUpdate(DocumentSnapshot snapshot) {
    try {
      if (!snapshot.exists) {
        _updateCurrentStatus(
          const GmailSyncStatus(
            isActive: false,
            currentStage: GmailSyncStage.completed,
            overallProgress: 0.0,
            recentLogs: [],
          ),
        );
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      final stage = _parseStage(data['currentStage'] as String?);
      final isActive = data['isActive'] as bool? ?? false;
      final progress = (data['overallProgress'] as num?)?.toDouble() ?? 0.0;
      final hasError = data['hasError'] as bool? ?? false;

      final startedAt = data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null;
      final lastUpdateAt = data['lastUpdateAt'] != null
          ? (data['lastUpdateAt'] as Timestamp).toDate()
          : null;

      final status = GmailSyncStatus(
        isActive: isActive,
        currentStage: stage,
        overallProgress: progress.clamp(0.0, 1.0),
        recentLogs: _currentStatus.recentLogs, // Keep existing logs
        startedAt: startedAt,
        lastUpdateAt: lastUpdateAt,
        metadata: data['metadata'] as Map<String, dynamic>?,
        hasError: hasError,
      );

      _updateCurrentStatus(status);

      debugPrint(
        '📊 [GMAIL SYNC STATUS] Updated: ${stage.name} (${(progress * 100).toStringAsFixed(1)}%)',
      );
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error handling status update: $e');
    }
  }

  /// Handle sync logs collection updates
  void _handleLogsUpdate(QuerySnapshot snapshot) {
    try {
      final logs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return GmailSyncLog(
          id: doc.id,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          stage: _parseStage(data['stage'] as String?),
          message: data['message'] as String? ?? '',
          metadata: data['metadata'] as Map<String, dynamic>?,
          isError: data['isError'] as bool? ?? false,
          progress: (data['progress'] as num?)?.toDouble(),
        );
      }).toList();

      // Update current status with new logs
      _updateCurrentStatus(_currentStatus.copyWith(recentLogs: logs));

      // Emit individual log events for newest logs
      if (logs.isNotEmpty) {
        _logController.add(logs.first);
      }

      debugPrint('📝 [GMAIL SYNC STATUS] Updated logs: ${logs.length} entries');
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error handling logs update: $e');
    }
  }

  /// Parse stage string to enum
  GmailSyncStage _parseStage(String? stageString) {
    if (stageString == null) return GmailSyncStage.completed;

    try {
      return GmailSyncStage.values.firstWhere(
        (stage) => stage.name == stageString,
        orElse: () => GmailSyncStage.completed,
      );
    } catch (e) {
      return GmailSyncStage.completed;
    }
  }

  /// Update current status and emit to stream
  void _updateCurrentStatus(GmailSyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Start Gmail sync (create initial status document)
  Future<void> startGmailSync() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('gmail_sync_status').doc(user.uid).set({
        'isActive': true,
        'currentStage': GmailSyncStage.connecting.name,
        'overallProgress': 0.0,
        'startedAt': FieldValue.serverTimestamp(),
        'lastUpdateAt': FieldValue.serverTimestamp(),
        'hasError': false,
        'metadata': {},
      });

      debugPrint('🚀 [GMAIL SYNC STATUS] Started Gmail sync tracking');
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error starting sync: $e');
    }
  }

  /// Update sync progress
  Future<void> updateSyncProgress(
    GmailSyncStage stage, {
    double? progress,
    String? message,
    Map<String, dynamic>? metadata,
    bool isError = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Update status document
      await _firestore.collection('gmail_sync_status').doc(user.uid).update({
        'currentStage': stage.name,
        'overallProgress': progress ?? _getStageProgress(stage),
        'lastUpdateAt': FieldValue.serverTimestamp(),
        'hasError': isError,
        if (metadata != null) 'metadata': metadata,
      });

      // Add log entry
      if (message != null) {
        await _firestore
            .collection('gmail_sync_status')
            .doc(user.uid)
            .collection('logs')
            .add({
              'timestamp': FieldValue.serverTimestamp(),
              'stage': stage.name,
              'message': message,
              'metadata': metadata,
              'isError': isError,
              'progress': progress,
            });
      }

      debugPrint('📊 [GMAIL SYNC STATUS] Progress updated: ${stage.name}');
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error updating progress: $e');
    }
  }

  /// Complete Gmail sync
  Future<void> completeSyncWithResults({
    required int totalEmails,
    required int newEmails,
    required Duration syncDuration,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('gmail_sync_status').doc(user.uid).update({
        'isActive': false,
        'currentStage': GmailSyncStage.completed.name,
        'overallProgress': 1.0,
        'lastUpdateAt': FieldValue.serverTimestamp(),
        'hasError': false,
        'metadata': {
          'totalEmails': totalEmails,
          'newEmails': newEmails,
          'syncDurationMs': syncDuration.inMilliseconds,
        },
      });

      // Add completion log
      await _firestore
          .collection('gmail_sync_status')
          .doc(user.uid)
          .collection('logs')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'stage': GmailSyncStage.completed.name,
            'message':
                'Gmail sync completed successfully! Processed $totalEmails emails ($newEmails new).',
            'metadata': {
              'totalEmails': totalEmails,
              'newEmails': newEmails,
              'syncDurationMs': syncDuration.inMilliseconds,
            },
            'isError': false,
            'progress': 1.0,
          });

      debugPrint('✅ [GMAIL SYNC STATUS] Sync completed: $totalEmails emails');
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error completing sync: $e');
    }
  }

  /// Mark sync as failed
  Future<void> failSyncWithError(String errorMessage) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('gmail_sync_status').doc(user.uid).update({
        'isActive': false,
        'currentStage': GmailSyncStage.failed.name,
        'lastUpdateAt': FieldValue.serverTimestamp(),
        'hasError': true,
        'metadata': {'errorMessage': errorMessage},
      });

      // Add error log
      await _firestore
          .collection('gmail_sync_status')
          .doc(user.uid)
          .collection('logs')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'stage': GmailSyncStage.failed.name,
            'message': errorMessage,
            'isError': true,
            'progress': 0.0,
          });

      debugPrint('❌ [GMAIL SYNC STATUS] Sync failed: $errorMessage');
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error recording failure: $e');
    }
  }

  /// Get default progress for a stage
  double _getStageProgress(GmailSyncStage stage) {
    switch (stage) {
      case GmailSyncStage.connecting:
        return 0.1;
      case GmailSyncStage.authenticating:
        return 0.2;
      case GmailSyncStage.fetchingThreads:
        return 0.3;
      case GmailSyncStage.fetchingMessages:
        return 0.5;
      case GmailSyncStage.processingContent:
        return 0.7;
      case GmailSyncStage.storingLocally:
        return 0.8;
      case GmailSyncStage.indexingData:
        return 0.9;
      case GmailSyncStage.updatingContext:
        return 0.95;
      case GmailSyncStage.completed:
        return 1.0;
      case GmailSyncStage.failed:
        return 0.0;
    }
  }

  /// Check if local storage has Gmail data and is ready
  Future<bool> isGmailDataReadyInLocalStorage() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Check if sync status indicates completion
      final statusDoc = await _firestore
          .collection('gmail_sync_status')
          .doc(user.uid)
          .get();

      if (!statusDoc.exists) {
        debugPrint(
          '📧 [GMAIL SYNC STATUS] No sync status found, assuming ready',
        );
        return true; // Assume ready if no active sync
      }

      final data = statusDoc.data()!;
      final isActive = data['isActive'] as bool? ?? false;
      final currentStage = data['currentStage'] as String?;
      final metadata = data['metadata'] as Map<String, dynamic>?;
      final totalEmails = metadata?['totalEmails'] as int? ?? 0;

      // Data is ready if sync is not active and completed successfully with emails processed
      final isReady =
          !isActive &&
          currentStage == GmailSyncStage.completed.name &&
          totalEmails > 0;

      debugPrint(
        '📧 [GMAIL SYNC STATUS] Gmail data ready: $isReady (active: $isActive, stage: $currentStage, emails: $totalEmails)',
      );
      return isReady;
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error checking local storage: $e');
      return false;
    }
  }

  /// Reset sync status (for manual sync restart)
  Future<void> resetSyncStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('gmail_sync_status').doc(user.uid).delete();

      debugPrint('🔄 [GMAIL SYNC STATUS] Reset sync status');
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error resetting status: $e');
    }
  }

  /// Clean up old logs (keep only recent 50)
  Future<void> cleanupOldLogs() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final logsQuery = await _firestore
          .collection('gmail_sync_status')
          .doc(user.uid)
          .collection('logs')
          .orderBy('timestamp', descending: false)
          .get();

      if (logsQuery.docs.length > 50) {
        final batch = _firestore.batch();
        final logsToDelete = logsQuery.docs.take(logsQuery.docs.length - 50);

        for (final doc in logsToDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        debugPrint('🧹 [GMAIL SYNC STATUS] Cleaned up old logs');
      }
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error cleaning up logs: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _statusSubscription?.cancel();
    _logsSubscription?.cancel();
    _statusController.close();
    _logController.close();
  }
}
