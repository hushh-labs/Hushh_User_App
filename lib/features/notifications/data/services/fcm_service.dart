import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../../discover/presentation/bloc/cart_bloc.dart';
import 'notification_service.dart';

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

      // Foreground data message handling
      FirebaseMessaging.onMessage.listen(_onMessage);

      // iOS: ensure foreground notifications are displayed when sent with notification payload
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Handle notification taps when app is in background/resumed
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

      // Handle the case when the app was launched by tapping a notification
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpened(initialMessage);
      }

      _isInitialized = true;
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize FCM Service: $e');
      _isInitialized = true;
    }
  }

  void _onMessage(RemoteMessage message) {
    try {
      final data = message.data;
      debugPrint('FCM onMessage data: $data');
      final type = data['type']?.toString();

      // Accept explicit type or infer from presence of bid payload
      final agentId = (data['agentId'] ?? data['agent_id'] ?? '').toString();
      final productId =
          (data['productId'] ??
                  data['product_id'] ??
                  data['id'] ??
                  data['sku'] ??
                  '')
              .toString();
      final productName = data['productName']?.toString();

      // Try to parse values from common keys
      double? discountAmount = double.tryParse(
        data['discount']?.toString() ?? '',
      );
      discountAmount ??= double.tryParse(
        data['discountAmount']?.toString() ?? '',
      );
      discountAmount ??= double.tryParse(
        data['bidAmount']?.toString() ?? '',
      ); // legacy

      final productPrice =
          double.tryParse(data['productPrice']?.toString() ?? '') ??
          double.tryParse(data['price']?.toString() ?? '');
      final bidPrice =
          double.tryParse(data['bidPrice']?.toString() ?? '') ??
          double.tryParse(data['offerPrice']?.toString() ?? '') ??
          double.tryParse(data['finalPrice']?.toString() ?? '');

      // Derive discount from price fields if available
      double? derivedDiscount;
      if (productPrice != null && bidPrice != null) {
        derivedDiscount = (productPrice - bidPrice).clamp(0, double.infinity);
      }

      final effectiveDiscount = derivedDiscount ?? discountAmount;
      final looksLikeBid =
          agentId.isNotEmpty &&
          productId.isNotEmpty &&
          effectiveDiscount != null;

      if (type == 'bid_approved' || looksLikeBid) {
        CartBloc? bloc;
        try {
          final instance = GetIt.instance<CartBloc>();
          if (!instance.isClosed) bloc = instance;
        } catch (_) {}

        if (bloc != null && looksLikeBid) {
          bloc.add(
            BidApprovedEvent(
              agentId: agentId,
              productId: productId,
              bidAmount: effectiveDiscount,
              productName: productName,
            ),
          );

          // Optional: show a foreground banner so user sees something immediately
          NotificationService().showLocalNotification(
            id: 'bid_${productId}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Bid received',
            body:
                derivedDiscount != null &&
                    productPrice != null &&
                    bidPrice != null
                ? 'New price \$${bidPrice.toStringAsFixed(2)} (saved \$${derivedDiscount.toStringAsFixed(2)})'
                : 'Discount \$${effectiveDiscount.toStringAsFixed(2)} applied',
          );

          // Optional quick action: navigate to cart or product detail if desired
          try {
            // final nav = di.GetIt.instance<NavigationService>();
            // Navigate to a cart or product route if you have named routes set up
            // nav.navigateTo('cart');
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _onMessageOpened(RemoteMessage message) {
    // For tap actions outside the app: apply discount and optionally navigate
    try {
      final data = message.data;
      final agentId = (data['agentId'] ?? data['agent_id'] ?? '').toString();
      final productId =
          (data['productId'] ??
                  data['product_id'] ??
                  data['id'] ??
                  data['sku'] ??
                  '')
              .toString();
      final productName = data['productName']?.toString();

      double? discountAmount = double.tryParse(
        data['discount']?.toString() ?? '',
      );
      discountAmount ??= double.tryParse(
        data['discountAmount']?.toString() ?? '',
      );
      discountAmount ??= double.tryParse(data['bidAmount']?.toString() ?? '');

      final productPrice =
          double.tryParse(data['productPrice']?.toString() ?? '') ??
          double.tryParse(data['price']?.toString() ?? '');
      final bidPrice =
          double.tryParse(data['bidPrice']?.toString() ?? '') ??
          double.tryParse(data['offerPrice']?.toString() ?? '') ??
          double.tryParse(data['finalPrice']?.toString() ?? '');
      double? derivedDiscount;
      if (productPrice != null && bidPrice != null) {
        derivedDiscount = (productPrice - bidPrice).clamp(0, double.infinity);
      }
      final effectiveDiscount = derivedDiscount ?? discountAmount;

      if (agentId.isEmpty || productId.isEmpty || effectiveDiscount == null)
        return;

      CartBloc? bloc;
      try {
        final instance = GetIt.instance<CartBloc>();
        if (!instance.isClosed) bloc = instance;
      } catch (_) {}

      bloc?.add(
        BidApprovedEvent(
          agentId: agentId,
          productId: productId,
          bidAmount: effectiveDiscount,
          productName: productName,
        ),
      );

      // Optional: navigate to cart
      try {
        // final nav = di.GetIt.instance<NavigationService>();
        // nav.navigateTo('cart');
      } catch (_) {}
    } catch (_) {}
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      debugPrint('=== REQUESTING FCM PERMISSIONS ===');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('=== FCM PERMISSION STATUS ===');
      debugPrint('Authorization Status: ${settings.authorizationStatus}');
      debugPrint('Alert Setting: ${settings.alert}');
      debugPrint('Badge Setting: ${settings.badge}');
      debugPrint('Sound Setting: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM permissions granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('❌ FCM permissions denied');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.notDetermined) {
        debugPrint('⏳ FCM permissions not determined');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('📱 FCM provisional permissions granted');
      }
    } catch (e) {
      debugPrint('❌ Error requesting FCM permissions: $e');
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
          // In simulator, try to get FCM token without APNS
          debugPrint('Trying to get FCM token without APNS token...');
          try {
            token = await _firebaseMessaging.getToken();
            if (token != null) {
              await _saveToken(token);
              _currentToken = token;
              debugPrint(
                'FCM Token obtained without APNS: ${token.substring(0, 20)}...',
              );
              return;
            }
          } catch (e) {
            debugPrint('Failed to get FCM token without APNS: $e');
          }
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

      // Check if we already have a valid token
      if (_currentToken != null) {
        debugPrint(
          'FCM token already exists, skipping generation: ${_currentToken!.substring(0, 20)}...',
        );
        return;
      }

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
