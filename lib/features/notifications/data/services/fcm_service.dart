import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _currentToken;
  bool _isInitialized = false;

  // Token storage keys
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmTokenTimestampKey = 'fcm_token_timestamp';

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Get and save initial token
      await _getAndSaveToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      _isInitialized = true;
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize FCM Service: $e');
      _isInitialized = true;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM permissions granted');
      } else {
        debugPrint('FCM permissions denied');
      }
    } catch (e) {
      debugPrint('Error requesting FCM permissions: $e');
    }
  }

  /// Get and save FCM token
  Future<void> _getAndSaveToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        await _saveToken(token);
        _currentToken = token;
        debugPrint('FCM Token obtained: ${token.substring(0, 20)}...');
        return;
      }

      // If FCM token is null, try to get APNS token first (iOS only)
      if (Platform.isIOS) {
        debugPrint('FCM token is null, trying to get APNS token first...');
        String? apnsToken = await _firebaseMessaging.getAPNSToken();

        if (apnsToken != null) {
          debugPrint('APNS token obtained: ${apnsToken.substring(0, 20)}...');
          // Try to get FCM token again after APNS token
          token = await _firebaseMessaging.getToken();
          if (token != null) {
            await _saveToken(token);
            _currentToken = token;
            debugPrint(
              'FCM Token obtained after APNS: ${token.substring(0, 20)}...',
            );
            return;
          }
        } else {
          debugPrint('APNS token not available - this is normal in simulator');
        }
      }

      debugPrint('Failed to get FCM token');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      // Don't rethrow for APNS token issues, just log and continue
      if (e.toString().contains('apns-token-not-set')) {
        debugPrint('APNS token not set - this is normal in simulator');
      }
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    try {
      debugPrint('FCM Token refreshed: ${newToken.substring(0, 20)}...');
      await _saveToken(newToken);
      _currentToken = newToken;
    } catch (e) {
      debugPrint('Error handling token refresh: $e');
    }
  }

  /// Save token to local storage and Firestore
  Future<void> _saveToken(String token) async {
    try {
      debugPrint('Saving FCM token: ${token.substring(0, 20)}...');

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      await prefs.setInt(
        _fcmTokenTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('FCM token saved to local storage');

      // Save to Firestore
      await _saveTokenToFirestore(token);
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Save token directly to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('HushUsers')
            .doc(user.uid)
            .set({
              'fcm_token': token,
              'platform': _getPlatform(),
              'last_token_update': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }, SetOptions(merge: true));
        debugPrint('FCM token saved to Firestore');
      } else {
        debugPrint('No user logged in, cannot save FCM token');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    if (_currentToken != null) {
      return _currentToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_fcmTokenKey);

      if (savedToken != null) {
        _currentToken = savedToken;
        return savedToken;
      }

      // Try to get fresh token
      final freshToken = await _firebaseMessaging.getToken();
      if (freshToken != null) {
        await _saveToken(freshToken);
        _currentToken = freshToken;
        return freshToken;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current FCM token: $e');
      return null;
    }
  }

  /// Force FCM token generation
  Future<void> forceTokenGeneration() async {
    try {
      debugPrint('Forcing FCM token generation...');

      // Try to get FCM token directly first
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        debugPrint('FCM token generated: ${token.substring(0, 20)}...');
        await _saveToken(token);
        return;
      }

      // If token is null and we're on iOS, try with APNS token
      if (Platform.isIOS) {
        debugPrint('Trying with APNS token...');
        String? apnsToken = await _firebaseMessaging.getAPNSToken();

        if (apnsToken != null) {
          debugPrint('APNS token obtained: ${apnsToken.substring(0, 20)}...');
          // Try to get FCM token again after APNS token
          token = await _firebaseMessaging.getToken();
          if (token != null) {
            debugPrint(
              'FCM token generated after APNS: ${token.substring(0, 20)}...',
            );
            await _saveToken(token);
            return;
          }
        } else {
          debugPrint('APNS token not available - this is normal in simulator');
        }
      }

      debugPrint('Failed to generate FCM token');
    } catch (e) {
      debugPrint('Error forcing FCM token generation: $e');
      // Don't rethrow for APNS token issues, just log and continue
      if (e.toString().contains('apns-token-not-set')) {
        debugPrint('APNS token not set - this is normal in simulator');
      }
    }
  }

  /// Get platform string
  String _getPlatform() {
    if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    } else {
      return 'unknown';
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
