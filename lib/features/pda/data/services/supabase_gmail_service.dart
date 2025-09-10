import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:get_it/get_it.dart';

import '../../domain/repositories/gmail_repository.dart';
import '../../domain/usecases/connect_gmail_usecase.dart';
import '../../domain/usecases/sync_gmail_usecase.dart';
import '../../domain/usecases/get_gmail_emails_usecase.dart';
import '../../domain/entities/gmail_email.dart';

/// Result class for Gmail operations
class GmailConnectionResult {
  final bool isSuccess;
  final String? error;
  final int? threadsCount;
  final int? messagesCount;

  GmailConnectionResult._({
    required this.isSuccess,
    this.error,
    this.threadsCount,
    this.messagesCount,
  });

  factory GmailConnectionResult.success({
    int? threadsCount,
    int? messagesCount,
  }) {
    return GmailConnectionResult._(
      isSuccess: true,
      threadsCount: threadsCount,
      messagesCount: messagesCount,
    );
  }

  factory GmailConnectionResult.failure(String error) {
    return GmailConnectionResult._(isSuccess: false, error: error);
  }
}

/// Service to handle Gmail OAuth connection and management with Supabase
class SupabaseGmailService {
  static final SupabaseGmailService _instance =
      SupabaseGmailService._internal();
  factory SupabaseGmailService() => _instance;
  SupabaseGmailService._internal();

  // final FirebaseFunctions _functions = FirebaseFunctions.instance; // Removed - not used directly
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetIt _getIt = GetIt.instance;

  // Stream controllers for real-time email detection
  final StreamController<List<GmailEmail>> _emailController =
      StreamController<List<GmailEmail>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isMonitoringEmails = false;

  // Google Sign-In instance (lazy initialization to prevent crashes)
  GoogleSignIn? _googleSignIn;

  // Lazy getters for use cases
  GmailRepository get _repository => _getIt<GmailRepository>();
  ConnectGmailUseCase get _connectUseCase => _getIt<ConnectGmailUseCase>();
  SyncGmailUseCase get _syncUseCase => _getIt<SyncGmailUseCase>();
  GetGmailEmailsUseCase get _getEmailsUseCase =>
      _getIt<GetGmailEmailsUseCase>();

  // Initialize Google Sign-In with proper configuration
  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn == null) {
      try {
        // Using the Web Client ID for server-side token exchange
        const webClientId =
            '53407187172-nremqtd8hlmnqbcc6jkfavlk6iljq803.apps.googleusercontent.com';

        _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile',
            'https://www.googleapis.com/auth/gmail.readonly',
          ],
          // For iOS, serverClientId is required for server-side access
          serverClientId: Platform.isIOS ? webClientId : null,
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

      return await _repository.isGmailConnected(user.uid);
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error checking connection status: $e');
      return false;
    }
  }

  /// Stream to listen to Gmail connection status changes
  Stream<bool> get gmailConnectionStream => _connectionController.stream;

  /// Stream to listen to email updates
  Stream<List<GmailEmail>> get emailsStream => _emailController.stream;

  /// Connect Gmail account by performing OAuth flow and showing sync dialog
  Future<GmailConnectionResult> connectGmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return GmailConnectionResult.failure('User not authenticated');
      }

      debugPrint('🔐 [GMAIL SERVICE] Starting Gmail OAuth flow...');

      // Get Google Sign-In instance with error handling
      final googleSignIn = _getGoogleSignIn();

      // Sign out first to ensure fresh authentication
      try {
        await googleSignIn.signOut();
        debugPrint(
          '🔐 [GMAIL SERVICE] Cleared previous Google Sign-In session',
        );
      } catch (e) {
        debugPrint('⚠️ [GMAIL SERVICE] Warning during signOut: $e');
      }

      // Start Google Sign-In flow
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
        debugPrint('🔐 [GMAIL SERVICE] Sign-in dialog presented');
      } catch (e) {
        debugPrint('❌ [GMAIL SERVICE] Sign-in failed: $e');
        return GmailConnectionResult.failure('Sign-in cancelled or failed: $e');
      }

      if (googleUser == null) {
        debugPrint('⚠️ [GMAIL SERVICE] Sign-in cancelled by user');
        return GmailConnectionResult.failure('Sign-in cancelled by user');
      }

      debugPrint(
        '✅ [GMAIL SERVICE] Successfully signed in as: ${googleUser.email}',
      );

      // Get authentication data
      final googleAuth = await googleUser.authentication;
      final serverAuthCode = googleUser.serverAuthCode;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      debugPrint('🔐 [GMAIL SERVICE] Retrieved authentication tokens:');
      debugPrint(
        '  - Server Auth Code: ${serverAuthCode != null ? "Present" : "Missing"}',
      );
      debugPrint(
        '  - Access Token: ${accessToken != null ? "Present" : "Missing"}',
      );
      debugPrint('  - ID Token: ${idToken != null ? "Present" : "Missing"}');

      if (serverAuthCode == null && accessToken == null) {
        debugPrint('❌ [GMAIL SERVICE] No auth tokens available');
        return GmailConnectionResult.failure(
          'Failed to get authentication tokens. Please try again.',
        );
      }

      // Connect Gmail using repository
      final success = await _connectUseCase.call(
        userId: user.uid,
        accessToken:
            serverAuthCode ?? accessToken!, // Use serverAuthCode if available
        refreshToken: null, // Will be obtained by server
        idToken: idToken,
        email: googleUser.email,
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/gmail.readonly',
        ],
      );

      if (success) {
        _connectionController.add(true);
        debugPrint('✅ [GMAIL SERVICE] Gmail connected successfully');
        return GmailConnectionResult.success();
      } else {
        return GmailConnectionResult.failure(
          'Failed to store Gmail connection',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [GMAIL SERVICE] Unexpected error connecting Gmail: $e');
      debugPrint('Stack trace: $stackTrace');
      return GmailConnectionResult.failure('Unexpected error: ${e.toString()}');
    }
  }

  /// Sync Gmail emails with specified options
  Future<GmailConnectionResult> syncEmails(SyncOptions syncOptions) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return GmailConnectionResult.failure('User not authenticated');
      }

      debugPrint(
        '🔄 [GMAIL SERVICE] Starting Gmail sync with options: ${syncOptions.duration.displayName}',
      );

      final result = await _syncUseCase.call(user.uid, syncOptions);

      if (result.isSuccess) {
        _notifyEmailsUpdated(user.uid);
        debugPrint(
          '✅ [GMAIL SERVICE] Gmail sync completed: ${result.emailCount} emails',
        );
        return GmailConnectionResult.success(messagesCount: result.emailCount);
      } else {
        return GmailConnectionResult.failure(result.error ?? 'Sync failed');
      }
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error during sync: $e');
      return GmailConnectionResult.failure('Sync error: $e');
    }
  }

  /// Sync new emails (incremental sync)
  Future<GmailConnectionResult> syncGmailNow() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return GmailConnectionResult.failure('User not authenticated');
      }

      debugPrint('🔄 [GMAIL SERVICE] Starting incremental Gmail sync...');

      final result = await _syncUseCase.syncNewEmails(user.uid);

      if (result.isSuccess) {
        _notifyEmailsUpdated(user.uid);
        debugPrint(
          '✅ [GMAIL SERVICE] Incremental sync completed: ${result.emailCount} total emails',
        );
        return GmailConnectionResult.success(messagesCount: result.emailCount);
      } else {
        return GmailConnectionResult.failure(
          result.error ?? 'Incremental sync failed',
        );
      }
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error during incremental sync: $e');
      return GmailConnectionResult.failure('Incremental sync error: $e');
    }
  }

  /// Disconnect Gmail account
  Future<GmailConnectionResult> disconnectGmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return GmailConnectionResult.failure('User not authenticated');
      }

      // Sign out from Google Sign-In
      try {
        final googleSignIn = _getGoogleSignIn();
        await googleSignIn.signOut();
        debugPrint('✅ [GMAIL SERVICE] Signed out from Google');
      } catch (e) {
        debugPrint('⚠️ [GMAIL SERVICE] Warning during Google sign-out: $e');
      }

      // Disconnect using repository
      final success = await _repository.disconnectGmail(user.uid);

      if (success) {
        _connectionController.add(false);
        debugPrint('✅ [GMAIL SERVICE] Gmail disconnected successfully');
        return GmailConnectionResult.success();
      } else {
        return GmailConnectionResult.failure('Failed to disconnect Gmail');
      }
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error disconnecting Gmail: $e');
      return GmailConnectionResult.failure('Failed to disconnect Gmail: $e');
    }
  }

  /// Get Gmail emails
  Future<List<GmailEmail>> getEmails({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      return await _getEmailsUseCase.call(
        user.uid,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error getting emails: $e');
      return [];
    }
  }

  /// Start email monitoring for real-time updates
  Future<void> startEmailMonitoring() async {
    if (_isMonitoringEmails) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final isConnected = await isGmailConnected();
      if (!isConnected) return;

      _isMonitoringEmails = true;
      debugPrint('📧 [GMAIL SERVICE] Starting email monitoring...');

      // Set up periodic sync for new emails (every 30 minutes)
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        if (!_isMonitoringEmails) {
          timer.cancel();
          return;
        }

        try {
          await syncGmailNow();
        } catch (e) {
          debugPrint('❌ [GMAIL SERVICE] Error in periodic sync: $e');
        }
      });

      // Initial notification
      _notifyEmailsUpdated(user.uid);

      debugPrint('✅ [GMAIL SERVICE] Email monitoring started');
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error starting email monitoring: $e');
    }
  }

  /// Stop email monitoring
  void stopEmailMonitoring() {
    _isMonitoringEmails = false;
    debugPrint('📧 [GMAIL SERVICE] Email monitoring stopped');
  }

  /// Notify listeners about email updates
  Future<void> _notifyEmailsUpdated(String userId) async {
    try {
      final emails = await _getEmailsUseCase.call(
        userId,
      ); // No limit = get all emails
      _emailController.add(emails);
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error notifying email updates: $e');
    }
  }

  /// Check if sync is needed on app startup
  Future<bool> checkSyncNeeded() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final account = await _repository.getGmailAccount(user.uid);
      return account?.needsSync ?? false;
    } catch (e) {
      debugPrint('❌ [GMAIL SERVICE] Error checking sync need: $e');
      return false;
    }
  }

  void dispose() {
    stopEmailMonitoring();
    _emailController.close();
    _connectionController.close();
  }
}
