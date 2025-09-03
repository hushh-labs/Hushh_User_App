import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle Gmail OAuth connection and management
class GmailConnectorService {
  static final GmailConnectorService _instance = GmailConnectorService._internal();
  factory GmailConnectorService() => _instance;
  GmailConnectorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controllers for real-time email detection
  final StreamController<List<EmailThreadSummary>> _emailThreadsController = 
      StreamController<List<EmailThreadSummary>>.broadcast();
  final StreamController<EmailEvent> _emailEventsController = 
      StreamController<EmailEvent>.broadcast();

  StreamSubscription<QuerySnapshot>? _threadsSubscription;
  List<EmailThreadSummary> _lastKnownThreads = [];
  bool _isMonitoringEmails = false;
  
  // Google Sign-In instance (lazy initialization to prevent crashes)
  GoogleSignIn? _googleSignIn;

  // Initialize Google Sign-In with proper configuration
  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn == null) {
      try {
        // Using the Web Client ID for server-side token exchange
        // This should match your OAuth 2.0 Web client from Google Cloud Console
        const webClientId = '53407187172-kg46cau2e5vomuuqvh3c9tndgeig9epd.apps.googleusercontent.com';
        
        _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile',
            'https://www.googleapis.com/auth/gmail.readonly',
          ],
          // For iOS, serverClientId is required for server-side access
          // For Android, it's configured in google-services.json
          serverClientId: Platform.isIOS ? webClientId : null,
          // Enable server auth code for token exchange
          hostedDomain: null,
        );
        
        debugPrint('✅ [GMAIL SERVICE] GoogleSignIn initialized successfully');
      } catch (e) {
        debugPrint('❌ [GMAIL SERVICE] Error initializing GoogleSignIn: $e');
        // Create a basic instance without serverClientId as fallback
        _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile',
            'https://www.googleapis.com/auth/gmail.readonly',
          ],
        );
      }
    }
    return _googleSignIn!;
  }

  /// Check if Gmail is connected for the current user
  Future<bool> isGmailConnected() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('gmailAccounts')
          .doc(user.uid)
          .get();

      return doc.exists && (doc.data()?['isConnected'] == true);
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error checking connection status: $e');
      return false;
    }
  }

  /// Stream to listen to Gmail connection status changes
  Stream<bool> get gmailConnectionStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('gmailAccounts')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists && (doc.data()?['isConnected'] == true));
  }

  /// Connect Gmail account by performing OAuth flow
  Future<GmailConnectionResult> connectGmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return GmailConnectionResult.failure('User not authenticated');
      }

      debugPrint('🔐 [GMAIL SERVICE] Starting Gmail OAuth flow...');
      debugPrint('🔐 [GMAIL SERVICE] Platform: ${Platform.operatingSystem}');
      
      // Get Google Sign-In instance with error handling
      final googleSignIn = _getGoogleSignIn();
      
      // Sign out first to ensure fresh authentication
      try {
        await googleSignIn.signOut();
        debugPrint('🔐 [GMAIL SERVICE] Cleared previous Google Sign-In session');
      } catch (e) {
        debugPrint('⚠️ [GMAIL SERVICE] Warning during signOut: $e');
      }

      // Start Google Sign-In flow with error handling
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
        debugPrint('🔐 [GMAIL SERVICE] Sign-in dialog presented');
      } catch (e) {
        debugPrint('❌ [GMAIL SERVICE] Sign-in failed: $e');
        
        // Provide specific error messages based on error type
        if (e.toString().contains('PlatformException')) {
          if (e.toString().contains('12501')) {
            return GmailConnectionResult.failure('Sign-in was cancelled');
          } else if (e.toString().contains('12500')) {
            return GmailConnectionResult.failure('Google Sign-In configuration error. Please check your setup.');
          } else if (e.toString().contains('7')) {
            return GmailConnectionResult.failure('Network error. Please check your connection.');
          }
        }
        
        return GmailConnectionResult.failure('Failed to sign in: ${e.toString()}');
      }
      
      if (googleUser == null) {
        debugPrint('🔐 [GMAIL SERVICE] User cancelled OAuth flow');
        return GmailConnectionResult.failure('OAuth flow cancelled by user');
      }

      debugPrint('🔐 [GMAIL SERVICE] Signed in as: ${googleUser.email}');

      // Get authentication details with error handling
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        debugPrint('🔐 [GMAIL SERVICE] Got authentication object');
      } catch (e) {
        debugPrint('❌ [GMAIL SERVICE] Failed to get authentication: $e');
        return GmailConnectionResult.failure('Failed to authenticate: ${e.toString()}');
      }
      
      // Try to get server auth code (may be null on some platforms)
      final String? serverAuthCode = googleAuth.serverAuthCode;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      debugPrint('🔐 [GMAIL SERVICE] Auth details:');
      debugPrint('  - Server Auth Code: ${serverAuthCode != null ? "Present" : "Missing"}');
      debugPrint('  - Access Token: ${accessToken != null ? "Present" : "Missing"}');
      debugPrint('  - ID Token: ${idToken != null ? "Present" : "Missing"}');

      // For iOS, we might need to use access token if server auth code is not available
      if (serverAuthCode == null && accessToken == null) {
        debugPrint('❌ [GMAIL SERVICE] No auth tokens available');
        return GmailConnectionResult.failure('Failed to get authentication tokens. Please try again.');
      }

      debugPrint('🔐 [GMAIL SERVICE] Exchanging tokens via Cloud Function...');

      // Exchange tokens via Cloud Function with fallback
      try {
        final callable = _functions.httpsCallable('exchangeGoogleAuthCode');
        final result = await callable.call({
          'serverAuthCode': serverAuthCode,
          'accessToken': accessToken, // Fallback for platforms without server auth code
          'idToken': idToken,
          'email': googleUser.email,
        });

        final data = result.data as Map<String, dynamic>;
        
        if (data['success'] == true) {
          debugPrint('✅ [GMAIL SERVICE] Gmail connected successfully');
          return GmailConnectionResult.success();
        } else {
          debugPrint('❌ [GMAIL SERVICE] Token exchange failed: ${data['error']}');
          return GmailConnectionResult.failure(
            data['error'] ?? 'Unknown error during token exchange'
          );
        }
      } catch (e) {
        debugPrint('❌ [GMAIL SERVICE] Cloud Function error: $e');
        return GmailConnectionResult.failure('Server error during token exchange: ${e.toString()}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [GMAIL SERVICE] Unexpected error connecting Gmail: $e');
      debugPrint('Stack trace: $stackTrace');
      return GmailConnectionResult.failure('Unexpected error: ${e.toString()}');
    }
  }

  /// Disconnect Gmail account
  Future<GmailConnectionResult> disconnectGmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return GmailConnectionResult.failure('User not authenticated');
      }

      // Sign out from Google Sign-In with error handling
      try {
        final googleSignIn = _getGoogleSignIn();
        await googleSignIn.signOut();
        debugPrint('✅ [GMAIL SERVICE] Signed out from Google');
      } catch (e) {
        debugPrint('⚠️ [GMAIL SERVICE] Warning during Google sign-out: $e');
        // Continue with disconnection even if sign-out fails
      }

      // Update Firestore to mark as disconnected
      await _firestore
          .collection('gmailAccounts')
          .doc(user.uid)
          .update({
        'isConnected': false,
        'disconnectedAt': FieldValue.serverTimestamp(),
      });

      // TODO: Call Cloud Function to revoke tokens and clean up server-side data
      // final callable = _functions.httpsCallable('disconnectGmail');
      // await callable.call();

      debugPrint('✅ [GMAIL SERVICE] Gmail disconnected successfully');
      return GmailConnectionResult.success();
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error disconnecting Gmail: $e');
      return GmailConnectionResult.failure('Failed to disconnect Gmail: $e');
    }
  }

  /// Trigger manual sync of Gmail data
  Future<GmailSyncResult> syncGmailNow() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return GmailSyncResult.failure('User not authenticated');
      }

      debugPrint('🔄 [GMAIL SERVICE] Starting manual Gmail sync...');

      final callable = _functions.httpsCallable('syncGmailNow');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        debugPrint('✅ [GMAIL SERVICE] Gmail sync completed successfully');
        return GmailSyncResult.success(
          threadsCount: data['threadsCount'] ?? 0,
          messagesCount: data['messagesCount'] ?? 0,
        );
      } else {
        return GmailSyncResult.failure(
          data['error'] ?? 'Unknown error during sync'
        );
      }
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error syncing Gmail: $e');
      return GmailSyncResult.failure('Failed to sync Gmail: $e');
    }
  }

  /// Get Gmail account info
  Future<Map<String, dynamic>?> getGmailAccountInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('gmailAccounts')
          .doc(user.uid)
          .get();

      return doc.data();
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error getting account info: $e');
      return null;
    }
  }

  /// Get Gmail threads stream for the current user
  Stream<List<Map<String, dynamic>>> getGmailThreadsStream({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('gmailThreads')
        .doc(user.uid)
        .collection('threads')
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList());
  }

  /// Stream that emits email thread summaries in real-time
  Stream<List<EmailThreadSummary>> get emailThreadsStream => _emailThreadsController.stream;

  /// Stream that emits email events (new, updated emails)
  Stream<EmailEvent> get emailEventsStream => _emailEventsController.stream;

  /// Start monitoring emails for real-time updates
  Future<void> startEmailMonitoring() async {
    if (_isMonitoringEmails) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final isConnected = await isGmailConnected();
    if (!isConnected) return;

    debugPrint('📧 [GMAIL SERVICE] Starting real-time email monitoring...');

    _isMonitoringEmails = true;

    // Subscribe to Gmail threads collection changes
    _threadsSubscription = _firestore
        .collection('gmailThreads')
        .doc(user.uid)
        .collection('threads')
        .orderBy('lastMessageAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) async {
      await _handleThreadsUpdate(snapshot);
    });
  }

  /// Stop monitoring emails
  void stopEmailMonitoring() {
    if (!_isMonitoringEmails) return;

    debugPrint('📧 [GMAIL SERVICE] Stopping email monitoring...');

    _threadsSubscription?.cancel();
    _threadsSubscription = null;
    _isMonitoringEmails = false;
    _lastKnownThreads.clear();
  }

  /// Handle threads collection updates and detect new emails
  Future<void> _handleThreadsUpdate(QuerySnapshot snapshot) async {
    try {
      final currentThreads = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmailThreadSummary.fromFirestore(doc.id, data);
      }).toList();

      // Detect new threads
      final newThreads = <EmailThreadSummary>[];
      for (final thread in currentThreads) {
        final existingThread = _lastKnownThreads
            .where((t) => t.threadId == thread.threadId)
            .firstOrNull;

        if (existingThread == null) {
          // This is a completely new thread
          newThreads.add(thread);
          debugPrint('📧 [GMAIL SERVICE] New email thread detected: ${thread.subject}');
        } else if (thread.lastMessageAt.isAfter(existingThread.lastMessageAt)) {
          // This thread has new messages
          newThreads.add(thread);
          debugPrint('📧 [GMAIL SERVICE] Updated email thread detected: ${thread.subject}');
        }
      }

      // Update the last known threads
      _lastKnownThreads = currentThreads;

      // Emit the updated threads list
      _emailThreadsController.add(currentThreads);

      // Emit new email events if any
      if (newThreads.isNotEmpty) {
        _emailEventsController.add(EmailEvent(
          type: EmailEventType.newEmails,
          threads: newThreads,
          timestamp: DateTime.now(),
        ));

        debugPrint('📧 [GMAIL SERVICE] Emitted ${newThreads.length} new email events');
      }
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error handling threads update: $e');
    }
  }

  /// Trigger sync and automatically update PDA context
  Future<GmailSyncResult> syncAndUpdateContext() async {
    try {
      debugPrint('🔄 [GMAIL SERVICE] Syncing Gmail and updating PDA context...');

      final syncResult = await syncGmailNow();
      if (syncResult.isSuccess) {
        // Emit a context refresh event
        _emailEventsController.add(EmailEvent(
          type: EmailEventType.contextRefresh,
          threads: [],
          timestamp: DateTime.now(),
        ));
      }

      return syncResult;
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error in sync and context update: $e');
      return GmailSyncResult.failure('Failed to sync and update context: $e');
    }
  }

  /// Check if there are recent emails (within last 5 minutes)
  Future<bool> hasRecentEmails() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

      final recentQuery = await _firestore
          .collection('gmailThreads')
          .doc(user.uid)
          .collection('threads')
          .where('lastMessageAt', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .limit(1)
          .get();

      return recentQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error checking recent emails: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopEmailMonitoring();
    _emailThreadsController.close();
    _emailEventsController.close();
  }

  /// Get recent email summaries for PDA prewarming
  Future<List<String>> getRecentEmailSummaries({int limit = 50}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final threadsQuery = await _firestore
          .collection('gmailThreads')
          .doc(user.uid)
          .collection('threads')
          .orderBy('lastMessageAt', descending: true)
          .limit(limit)
          .get();

      final summaries = <String>[];
      
      for (final doc in threadsQuery.docs) {
        final data = doc.data();
        final subject = data['subject'] ?? 'No Subject';
        final snippet = data['snippet'] ?? '';
        final from = data['from'] ?? 'Unknown Sender';
        final lastMessageAt = data['lastMessageAt'];
        
        // Create a concise summary for each thread
        final timeAgo = lastMessageAt != null 
            ? _formatTimeAgo((lastMessageAt as Timestamp).toDate())
            : 'recently';
            
        final summary = 'Email from $from ($timeAgo): "$subject" - ${snippet.length > 100 ? snippet.substring(0, 100) + '...' : snippet}';
        summaries.add(summary);
      }

      return summaries;
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error getting email summaries: $e');
      return [];
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}

/// Represents an email thread summary
class EmailThreadSummary {
  final String threadId;
  final String subject;
  final String snippet;
  final String from;
  final DateTime lastMessageAt;
  final int messageCount;
  final List<String> labels;

  EmailThreadSummary({
    required this.threadId,
    required this.subject,
    required this.snippet,
    required this.from,
    required this.lastMessageAt,
    required this.messageCount,
    required this.labels,
  });

  factory EmailThreadSummary.fromFirestore(String id, Map<String, dynamic> data) {
    return EmailThreadSummary(
      threadId: id,
      subject: data['subject'] ?? 'No Subject',
      snippet: data['snippet'] ?? '',
      from: data['from'] ?? 'Unknown Sender',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageCount: data['messageCount'] ?? 1,
      labels: List<String>.from(data['labels'] ?? []),
    );
  }

  String get formattedSummary {
    final timeAgo = _formatTimeAgo(lastMessageAt);
    return 'Email from $from ($timeAgo): "$subject" - ${snippet.length > 100 ? snippet.substring(0, 100) + '...' : snippet}';
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}

/// Email event types
enum EmailEventType {
  newEmails,
  contextRefresh,
}

/// Represents an email event (new emails, context refresh, etc.)
class EmailEvent {
  final EmailEventType type;
  final List<EmailThreadSummary> threads;
  final DateTime timestamp;

  EmailEvent({
    required this.type,
    required this.threads,
    required this.timestamp,
  });
}

/// Result class for Gmail connection operations
class GmailConnectionResult {
  final bool isSuccess;
  final String? error;

  GmailConnectionResult.success() : isSuccess = true, error = null;
  GmailConnectionResult.failure(this.error) : isSuccess = false;
}

/// Result class for Gmail sync operations
class GmailSyncResult {
  final bool isSuccess;
  final String? error;
  final int threadsCount;
  final int messagesCount;

  GmailSyncResult.success({
    required this.threadsCount,
    required this.messagesCount,
  }) : isSuccess = true, error = null;
  
  GmailSyncResult.failure(this.error) 
      : isSuccess = false, threadsCount = 0, messagesCount = 0;
}
