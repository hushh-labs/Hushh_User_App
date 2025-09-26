import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Secure Firebase Remote Config service for managing payment configuration
///
/// SECURITY NOTE: This file contains NO real keys - only safe defaults.
/// Real keys are stored securely in Firebase Remote Config and fetched at runtime.
class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;
  static bool _isInitialized = false;

  /// Initialize Remote Config with secure defaults
  ///
  /// IMPORTANT: All defaults here are SAFE for Git - no real keys!
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure Remote Config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set SAFE default values - NO REAL KEYS HERE!
      await _remoteConfig.setDefaults({
        // Payment Configuration (SAFE DEFAULTS ONLY)
        'razorpay_key_id': 'demo_key_placeholder', // Safe placeholder
        'razorpay_key_secret': '', // Empty by default
        'razorpay_demo_mode': true, // Always default to demo mode
        // Stripe Configuration (SAFE DEFAULTS ONLY)
        'stripe_publishable_key':
            'pk_test_demo_placeholder', // Safe placeholder
        'stripe_secret_key': '', // Empty by default
        'stripe_demo_mode': true, // Always default to demo mode
        // Environment Configuration
        'app_environment': 'development', // Safe default
        'payment_enabled': false, // Safe default - disabled
      });

      // Fetch and activate remote values
      await _remoteConfig.fetchAndActivate();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Remote Config initialized successfully');
        print('📊 Demo mode: ${isDemoMode}');
        print('🌍 Environment: ${environment}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Remote Config initialization failed: $e');
        print('🔄 Continuing with safe defaults');
      }
      _isInitialized = true; // Continue with defaults
    }
  }

  /// Razorpay Key ID (fetched securely from Firebase)
  static String get razorpayKeyId {
    final key = _remoteConfig.getString('razorpay_key_id');
    if (kDebugMode && key == 'demo_key_placeholder') {
      print(
        '⚠️  Using demo Razorpay key - configure real keys in Firebase Console',
      );
    }
    return key;
  }

  /// Razorpay Key Secret (fetched securely from Firebase)
  static String get razorpayKeySecret {
    final secret = _remoteConfig.getString('razorpay_key_secret');
    return secret;
  }

  /// Stripe Publishable Key (fetched securely from Firebase)
  static String get stripePublishableKey {
    final key = _remoteConfig.getString('stripe_publishable_key');
    if (kDebugMode && key == 'pk_test_demo_placeholder') {
      print(
        '⚠️  Using demo Stripe key - configure real keys in Firebase Console',
      );
    }
    return key;
  }

  /// Stripe Secret Key (fetched securely from Firebase)
  static String get stripeSecretKey {
    final secret = _remoteConfig.getString('stripe_secret_key');
    return secret;
  }

  /// Check if we're in demo mode for Razorpay
  static bool get isDemoMode {
    final demoMode = _remoteConfig.getBool('razorpay_demo_mode');

    // Additional safety check - if key looks like placeholder, force demo mode
    final keyId = razorpayKeyId;
    if (keyId == 'demo_key_placeholder' ||
        keyId.contains('placeholder') ||
        keyId.contains('demo') ||
        keyId.isEmpty) {
      return true;
    }

    return demoMode;
  }

  /// Check if we're in demo mode for Stripe
  static bool get isStripeDemoMode {
    final demoMode = _remoteConfig.getBool('stripe_demo_mode');

    // Additional safety check
    final key = stripePublishableKey;
    if (key == 'pk_test_demo_placeholder' ||
        key.contains('placeholder') ||
        key.contains('demo') ||
        key.isEmpty) {
      return true;
    }

    return demoMode;
  }

  /// Get current environment (development/staging/production)
  static String get environment {
    return _remoteConfig.getString('app_environment');
  }

  /// Check if payments are enabled
  static bool get isPaymentEnabled {
    return _remoteConfig.getBool('payment_enabled');
  }

  /// Check if the service is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Refresh configuration from Firebase (useful for testing)
  static Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      if (kDebugMode) {
        print('🔄 Remote Config refreshed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Remote Config refresh failed: $e');
      }
    }
  }

  /// Get all current config values (for debugging)
  static Map<String, dynamic> getAllConfig() {
    if (!_isInitialized) {
      return {'error': 'Not initialized'};
    }

    return {
      'razorpay_demo_mode': isDemoMode,
      'stripe_demo_mode': isStripeDemoMode,
      'environment': environment,
      'payment_enabled': isPaymentEnabled,
      'initialized': _isInitialized,
      // Note: We don't expose actual keys for security
      'razorpay_key_configured':
          razorpayKeyId.isNotEmpty && !razorpayKeyId.contains('placeholder'),
      'stripe_key_configured':
          stripePublishableKey.isNotEmpty &&
          !stripePublishableKey.contains('placeholder'),
    };
  }
}
