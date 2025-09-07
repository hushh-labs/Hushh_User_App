import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleMeetCacheManager {
  static const String _cacheKey = 'google_meet_context_cache';
  static const String _lastUpdateKey = 'google_meet_last_update';
  static const Duration _cacheValidDuration = Duration(hours: 6);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if cache is still valid
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);

      if (lastUpdateStr == null) return false;

      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();

      final isValid = now.difference(lastUpdate) < _cacheValidDuration;
      debugPrint('📦 [GOOGLE MEET CACHE] Cache valid: $isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET CACHE] Error checking cache validity: $e');
      return false;
    }
  }

  /// Load Google Meet context from local cache
  Future<Map<String, dynamic>> loadGoogleMeetContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextJson = prefs.getString(_cacheKey);

      if (contextJson != null) {
        final context = jsonDecode(contextJson) as Map<String, dynamic>;
        debugPrint('📦 [GOOGLE MEET CACHE] Loaded from local cache');
        return context;
      }

      debugPrint('📦 [GOOGLE MEET CACHE] No local cache found');
      return {};
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET CACHE] Error loading from local cache: $e');
      return {};
    }
  }

  /// Store Google Meet context in local cache
  Future<void> storeGoogleMeetContext(Map<String, dynamic> context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(context));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());

      debugPrint('💾 [GOOGLE MEET CACHE] Context cached locally');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET CACHE] Error storing in local cache: $e');
    }
  }

  /// Store Google Meet context in Firestore for backup
  Future<void> storeGoogleMeetContextInFirestore(
    Map<String, dynamic> context,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('google_meet_context_cache')
          .doc(user.uid)
          .set({
            'context': context,
            'lastUpdated': FieldValue.serverTimestamp(),
            'version': '1.0',
          });

      debugPrint('💾 [GOOGLE MEET CACHE] Context stored in Firestore');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET CACHE] Error storing in Firestore: $e');
    }
  }

  /// Load Google Meet context from Firestore
  Future<Map<String, dynamic>> loadGoogleMeetContextFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final doc = await _firestore
          .collection('google_meet_context_cache')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final context = data['context'] as Map<String, dynamic>? ?? {};
        debugPrint('📦 [GOOGLE MEET CACHE] Loaded from Firestore');
        return context;
      }

      debugPrint('📦 [GOOGLE MEET CACHE] No Firestore cache found');
      return {};
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET CACHE] Error loading from Firestore: $e');
      return {};
    }
  }

  /// Clear all Google Meet caches
  Future<void> clearAllCaches() async {
    try {
      final user = _auth.currentUser;

      // Clear local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);

      // Clear Firestore cache
      if (user != null) {
        await _firestore
            .collection('google_meet_context_cache')
            .doc(user.uid)
            .delete();
      }

      debugPrint('🧹 [GOOGLE MEET CACHE] All caches cleared');
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET CACHE] Error clearing caches: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      final contextJson = prefs.getString(_cacheKey);

      final stats = {
        'hasLocalCache': contextJson != null,
        'lastUpdate': lastUpdateStr,
        'isValid': await isCacheValid(),
        'cacheSize': contextJson?.length ?? 0,
      };

      debugPrint('📊 [GOOGLE MEET CACHE] Cache stats: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET CACHE] Error getting cache stats: $e');
      return {};
    }
  }
}
