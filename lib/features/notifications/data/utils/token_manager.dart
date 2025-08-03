import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fcm_service.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  static const String _tokenHashKey = 'fcm_token_hash';
  static const String _tokenValidationKey = 'fcm_token_validation';
  static const String _lastTokenUpdateKey = 'fcm_last_token_update';

  final FCMService _fcmService = FCMService();

  /// Get and validate FCM token
  Future<String?> getValidToken() async {
    try {
      final token = await _fcmService.getCurrentToken();
      if (token != null && await _validateToken(token)) {
        return token;
      }

      // Token is invalid or expired, force generation
      await _fcmService.forceTokenGeneration();
      final newToken = await _fcmService.getCurrentToken();

      if (newToken != null && await _validateToken(newToken)) {
        return newToken;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate FCM token format and integrity
  Future<bool> _validateToken(String token) async {
    try {
      // Basic token format validation
      if (token.isEmpty || token.length < 100) {
        return false;
      }

      // Check if token has changed (integrity check)
      final prefs = await SharedPreferences.getInstance();
      final savedHash = prefs.getString(_tokenHashKey);
      final currentHash = _generateTokenHash(token);

      if (savedHash != null && savedHash != currentHash) {
        // Token has changed, update hash
        await prefs.setString(_tokenHashKey, currentHash);
        await prefs.setBool(_tokenValidationKey, true);
        await prefs.setInt(
          _lastTokenUpdateKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return true;
      }

      // Check if token is expired (older than 30 days)
      final lastUpdate = prefs.getInt(_lastTokenUpdateKey);
      if (lastUpdate != null) {
        final lastUpdateDate = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
        final now = DateTime.now();
        final difference = now.difference(lastUpdateDate);

        if (difference.inDays > 30) {
          return false; // Token is expired
        }
      }

      return prefs.getBool(_tokenValidationKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Generate hash for token integrity checking
  String _generateTokenHash(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Save token with validation
  Future<bool> saveToken(String token) async {
    try {
      if (await _validateToken(token)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenHashKey, _generateTokenHash(token));
        await prefs.setBool(_tokenValidationKey, true);
        await prefs.setInt(
          _lastTokenUpdateKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear all token data
  Future<void> clearTokenData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenHashKey);
      await prefs.remove(_tokenValidationKey);
      await prefs.remove(_lastTokenUpdateKey);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get token metadata
  Future<Map<String, dynamic>> getTokenMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastTokenUpdateKey);
      final isValid = prefs.getBool(_tokenValidationKey) ?? false;

      return {
        'lastUpdate': lastUpdate != null
            ? DateTime.fromMillisecondsSinceEpoch(lastUpdate)
            : null,
        'isValid': isValid,
        'isExpired': lastUpdate != null
            ? DateTime.now()
                      .difference(
                        DateTime.fromMillisecondsSinceEpoch(lastUpdate),
                      )
                      .inDays >
                  30
            : true,
        'platform': Platform.isIOS ? 'ios' : 'android',
      };
    } catch (e) {
      return {};
    }
  }

  /// Check if token needs refresh
  Future<bool> needsTokenRefresh() async {
    try {
      final metadata = await getTokenMetadata();
      final lastUpdate = metadata['lastUpdate'] as DateTime?;

      if (lastUpdate == null) return true;

      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      // Refresh if older than 25 days (before 30-day expiration)
      return difference.inDays > 25;
    } catch (e) {
      return true;
    }
  }

  /// Force token refresh
  Future<String?> forceTokenRefresh() async {
    try {
      await _fcmService.forceTokenGeneration();
      final newToken = await _fcmService.getCurrentToken();

      if (newToken != null) {
        await saveToken(newToken);
        return newToken;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get token statistics
  Future<Map<String, dynamic>> getTokenStats() async {
    try {
      final metadata = await getTokenMetadata();
      final currentToken = await _fcmService.getCurrentToken();

      return {
        'hasValidToken': currentToken != null,
        'tokenLength': currentToken?.length ?? 0,
        'lastUpdate': metadata['lastUpdate'],
        'isExpired': metadata['isExpired'],
        'platform': metadata['platform'],
        'fcmInitialized': _fcmService.isInitialized,
      };
    } catch (e) {
      return {};
    }
  }

  /// Validate token format
  bool isValidTokenFormat(String token) {
    if (token.isEmpty) return false;

    // Basic FCM token format validation
    // FCM tokens are typically 140+ characters and contain alphanumeric characters
    if (token.length < 100) return false;

    // Check for common FCM token patterns
    final validPattern = RegExp(r'^[A-Za-z0-9:_-]+$');
    return validPattern.hasMatch(token);
  }

  /// Encrypt token for secure storage (basic implementation)
  String encryptToken(String token) {
    // In a real app, you would use proper encryption
    // This is a basic implementation for demonstration
    final bytes = utf8.encode(token);
    final encoded = base64.encode(bytes);
    return encoded;
  }

  /// Decrypt token from secure storage
  String decryptToken(String encryptedToken) {
    // In a real app, you would use proper decryption
    // This is a basic implementation for demonstration
    final bytes = base64.decode(encryptedToken);
    return utf8.decode(bytes);
  }
}
