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
        // Vertex AI Configuration
        'vertex_ai_project_id': 'your-gcp-project-id',
        'vertex_ai_location': 'us-central1',
        'vertex_ai_model': 'claude-sonnet-4@20250514',
        'vertex_ai_service_account_key': '',
        'vertex_ai_max_tokens': '1024',
        'vertex_ai_temperature': '0.7',
        'vertex_ai_top_p': '0.95',
        'vertex_ai_top_k': '40',
        'vertex_ai_max_conversation_history': '5',
        'vertex_ai_max_recent_messages': '20',
        'vertex_ai_max_stored_messages': '100',

        // Supabase Configuration
        'supabase_url': 'https://biiqwforuvzgubrrkfgq.supabase.co',
        'supabase_anon_key': '',
        'supabase_service_role_key': '',

        // LinkedIn Configuration
        'linkedin_client_id': '',
        'linkedin_client_secret': '',
        'linkedin_redirect_uri':
            'https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/linkedin-comprehensive-sync',

        // Gemini Configuration
        'gemini_api_key': '',

        // Google Meet Configuration
        'google_meet_client_id': '',
        'google_meet_client_secret': '',
        'google_meet_redirect_uri': '',
        'google_meet_sync_function_url': '',

        // Additional missing variables
        'linkedin_client_secret': '',
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

  /// Check if Remote Config is initialized
  static bool get isInitialized => _isInitialized;

  /// Razorpay Key ID (fetched securely from Firebase)
  static String get razorpayKeyId {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('⚠️ Remote Config not initialized, using default');
      }
      return 'demo_key_placeholder';
    }

    try {
      final key = _remoteConfig.getString('razorpay_key_id');
      if (kDebugMode && key == 'demo_key_placeholder') {
        print(
          '⚠️  Using demo Razorpay key - configure real keys in Firebase Console',
        );
      }
      return key;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting Razorpay key: $e');
      }
      return 'demo_key_placeholder';
    }
  }

  /// Razorpay Key Secret (fetched securely from Firebase)
  static String get razorpayKeySecret {
    final secret = _remoteConfig.getString('razorpay_key_secret');
    return secret;
  }

  /// Stripe Publishable Key (fetched securely from Firebase)
  static String get stripePublishableKey {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('⚠️ Remote Config not initialized, using default Stripe key');
      }
      return 'pk_test_demo_placeholder';
    }

    try {
      final key = _remoteConfig.getString('stripe_publishable_key');
      if (kDebugMode && key == 'pk_test_demo_placeholder') {
        print(
          '⚠️  Using demo Stripe key - configure real keys in Firebase Console',
        );
      }
      return key;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting Stripe key: $e');
      }
      return 'pk_test_demo_placeholder';
    }
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
        keyId.isEmpty) {
      return true;
    }

    // Allow test keys (rzp_test_) to work with real Razorpay plugin
    // Only force demo mode for actual placeholder keys, not test keys
    return demoMode;
  }

  /// Check if we're in demo mode for Stripe
  static bool get isStripeDemoMode {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('⚠️ Remote Config not initialized, defaulting to demo mode');
      }
      return true;
    }

    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting Stripe demo mode: $e');
      }
      return true; // Default to demo mode on error
    }
  }

  /// Get current environment (development/staging/production)
  static String get environment {
    return _remoteConfig.getString('app_environment');
  }

  /// Check if payments are enabled
  static bool get isPaymentEnabled {
    return _remoteConfig.getBool('payment_enabled');
  }

  // Vertex AI Configuration
  static String get vertexAiProjectId =>
      _remoteConfig.getString('vertex_ai_project_id');
  static String get vertexAiLocation =>
      _remoteConfig.getString('vertex_ai_location');
  static String get vertexAiModel => _remoteConfig.getString('vertex_ai_model');
  static String get vertexAiServiceAccountKey =>
      _remoteConfig.getString('vertex_ai_service_account_key');
  static String get vertexAiMaxTokens =>
      _remoteConfig.getString('vertex_ai_max_tokens');
  static String get vertexAiTemperature =>
      _remoteConfig.getString('vertex_ai_temperature');
  static String get vertexAiTopP => _remoteConfig.getString('vertex_ai_top_p');
  static String get vertexAiTopK => _remoteConfig.getString('vertex_ai_top_k');
  static String get vertexAiMaxConversationHistory =>
      _remoteConfig.getString('vertex_ai_max_conversation_history');
  static String get vertexAiMaxRecentMessages =>
      _remoteConfig.getString('vertex_ai_max_recent_messages');
  static String get vertexAiMaxStoredMessages =>
      _remoteConfig.getString('vertex_ai_max_stored_messages');

  // Supabase Configuration
  static String get supabaseUrl => _remoteConfig.getString('supabase_url');
  static String get supabaseAnonKey =>
      _remoteConfig.getString('supabase_anon_key');
  static String get supabaseServiceRoleKey =>
      _remoteConfig.getString('supabase_service_role_key');

  // LinkedIn Configuration
  static String get linkedinClientId =>
      _remoteConfig.getString('linkedin_client_id');
  static String get linkedinClientSecret =>
      _remoteConfig.getString('linkedin_client_secret');
  static String get linkedinRedirectUri =>
      _remoteConfig.getString('linkedin_redirect_uri');

  // Gemini Configuration
  static String get geminiApiKey => _remoteConfig.getString('gemini_api_key');

  // Google Meet Configuration
  static String get googleMeetClientId =>
      _remoteConfig.getString('google_meet_client_id');
  static String get googleMeetClientSecret =>
      _remoteConfig.getString('google_meet_client_secret');
  static String get googleMeetRedirectUri =>
      _remoteConfig.getString('google_meet_redirect_uri');
  static String get googleMeetSyncFunctionUrl =>
      _remoteConfig.getString('google_meet_sync_function_url');

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
