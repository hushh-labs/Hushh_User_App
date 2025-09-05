import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache manager for LinkedIn context data
class LinkedInCacheManager {
  static final LinkedInCacheManager _instance =
      LinkedInCacheManager._internal();
  factory LinkedInCacheManager() => _instance;
  LinkedInCacheManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache keys
  static const String _linkedInContextKey = 'linkedin_context_cache';
  static const String _lastUpdateKey = 'linkedin_context_last_update';
  static const String _cacheVersionKey = 'linkedin_context_version';

  // Cache configuration
  static const Duration _cacheValidityDuration = Duration(hours: 1);
  static const String _currentCacheVersion = '1.0';
  static const int _maxCacheSize = 1024 * 1024; // 1MB limit

  /// Store LinkedIn context in local cache
  Future<void> storeLinkedInContext(Map<String, dynamic> context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();

      // Serialize context to JSON
      final contextJson = jsonEncode(context);

      // Check cache size
      if (contextJson.length > _maxCacheSize) {
        debugPrint(
          '⚠️ [LINKEDIN CACHE] Context too large, storing summary only',
        );
        final summaryContext = {
          'summary': context['summary'],
          'timestamp': context['timestamp'],
          'account': context['account'],
        };
        final summaryJson = jsonEncode(summaryContext);
        await prefs.setString(_linkedInContextKey, summaryJson);
      } else {
        await prefs.setString(_linkedInContextKey, contextJson);
      }

      // Store metadata
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      await prefs.setString(_cacheVersionKey, _currentCacheVersion);

      debugPrint('💾 [LINKEDIN CACHE] Context stored in local cache');
    } catch (e) {
      debugPrint('❌ [LINKEDIN CACHE] Error storing context in local cache: $e');
    }
  }

  /// Load LinkedIn context from local cache
  Future<Map<String, dynamic>> loadLinkedInContext() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists
      if (!prefs.containsKey(_linkedInContextKey)) {
        debugPrint('📦 [LINKEDIN CACHE] No local cache found');
        return {};
      }

      // Check cache version
      final cacheVersion = prefs.getString(_cacheVersionKey);
      if (cacheVersion != _currentCacheVersion) {
        debugPrint(
          '🔄 [LINKEDIN CACHE] Cache version mismatch, clearing cache',
        );
        await clearLocalCache();
        return {};
      }

      // Check cache validity
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        if (DateTime.now().difference(lastUpdate) > _cacheValidityDuration) {
          debugPrint('⏰ [LINKEDIN CACHE] Cache expired, clearing cache');
          await clearLocalCache();
          return {};
        }
      }

      // Load context
      final contextJson = prefs.getString(_linkedInContextKey);
      if (contextJson != null) {
        final context = jsonDecode(contextJson) as Map<String, dynamic>;
        debugPrint('📦 [LINKEDIN CACHE] Context loaded from local cache');
        return context;
      }

      return {};
    } catch (e) {
      debugPrint(
        '❌ [LINKEDIN CACHE] Error loading context from local cache: $e',
      );
      return {};
    }
  }

  /// Store LinkedIn context in Firestore for persistence
  Future<void> storeLinkedInContextInFirestore(
    Map<String, dynamic> context,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Compress context for storage
      final compressedContext = _compressContext(context);

      await _firestore.collection('linkedin_context_cache').doc(user.uid).set({
        'context': compressedContext,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': _currentCacheVersion,
        'size': compressedContext.toString().length,
      });

      debugPrint('💾 [LINKEDIN CACHE] Context stored in Firestore');
    } catch (e) {
      debugPrint('❌ [LINKEDIN CACHE] Error storing context in Firestore: $e');
    }
  }

  /// Load LinkedIn context from Firestore
  Future<Map<String, dynamic>> loadLinkedInContextFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final doc = await _firestore
          .collection('linkedin_context_cache')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final context = data['context'] as Map<String, dynamic>?;
        final version = data['version'] as String?;

        if (context != null && version == _currentCacheVersion) {
          // Decompress context
          final decompressedContext = _decompressContext(context);
          debugPrint('📦 [LINKEDIN CACHE] Context loaded from Firestore');
          return decompressedContext;
        } else {
          debugPrint('🔄 [LINKEDIN CACHE] Firestore cache version mismatch');
        }
      }

      return {};
    } catch (e) {
      debugPrint('❌ [LINKEDIN CACHE] Error loading context from Firestore: $e');
      return {};
    }
  }

  /// Compress context by removing unnecessary data
  Map<String, dynamic> _compressContext(Map<String, dynamic> context) {
    final compressed = <String, dynamic>{};

    // Always keep summary and timestamp
    compressed['summary'] = context['summary'];
    compressed['timestamp'] = context['timestamp'];

    // Keep account info
    if (context['account'] != null) {
      compressed['account'] = context['account'];
    }

    // Keep only essential data from other sections
    if (context['posts'] != null) {
      final posts = context['posts'] as List;
      compressed['posts'] = posts.take(5).toList(); // Keep only 5 recent posts
    }

    if (context['connections'] != null) {
      final connections = context['connections'] as List;
      compressed['connections'] = connections
          .take(10)
          .toList(); // Keep only 10 connections
    }

    if (context['positions'] != null) {
      compressed['positions'] = context['positions']; // Keep all positions
    }

    if (context['education'] != null) {
      compressed['education'] = context['education']; // Keep all education
    }

    if (context['skills'] != null) {
      final skills = context['skills'] as List;
      compressed['skills'] = skills.take(20).toList(); // Keep top 20 skills
    }

    return compressed;
  }

  /// Decompress context by restoring full data if needed
  Map<String, dynamic> _decompressContext(Map<String, dynamic> context) {
    // For now, just return as-is since we're not doing heavy compression
    // In the future, we could implement more sophisticated compression
    return context;
  }

  /// Clear local cache
  Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_linkedInContextKey);
      await prefs.remove(_lastUpdateKey);
      await prefs.remove(_cacheVersionKey);
      debugPrint('🧹 [LINKEDIN CACHE] Local cache cleared');
    } catch (e) {
      debugPrint('❌ [LINKEDIN CACHE] Error clearing local cache: $e');
    }
  }

  /// Clear Firestore cache
  Future<void> clearFirestoreCache() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('linkedin_context_cache')
          .doc(user.uid)
          .delete();

      debugPrint('🧹 [LINKEDIN CACHE] Firestore cache cleared');
    } catch (e) {
      debugPrint('❌ [LINKEDIN CACHE] Error clearing Firestore cache: $e');
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await Future.wait([clearLocalCache(), clearFirestoreCache()]);
    debugPrint('🧹 [LINKEDIN CACHE] All caches cleared');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final prefs = await SharedPreferences.getInstance();
      final contextJson = prefs.getString(_linkedInContextKey);
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      final version = prefs.getString(_cacheVersionKey);

      // Get Firestore cache size
      int firestoreSize = 0;
      try {
        final doc = await _firestore
            .collection('linkedin_context_cache')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          firestoreSize = data['size'] as int? ?? 0;
        }
      } catch (e) {
        // Ignore errors for stats
      }

      return {
        'hasLocalCache': contextJson != null,
        'localCacheSize': contextJson?.length ?? 0,
        'firestoreCacheSize': firestoreSize,
        'lastUpdate': lastUpdateStr,
        'version': version,
        'isValid':
            lastUpdateStr != null &&
            DateTime.now().difference(DateTime.parse(lastUpdateStr)) <
                _cacheValidityDuration,
      };
    } catch (e) {
      debugPrint('❌ [LINKEDIN CACHE] Error getting cache stats: $e');
      return {};
    }
  }

  /// Check if cache is valid and not expired
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);

      if (lastUpdateStr == null) return false;

      final lastUpdate = DateTime.parse(lastUpdateStr);
      return DateTime.now().difference(lastUpdate) < _cacheValidityDuration;
    } catch (e) {
      debugPrint('❌ [LINKEDIN CACHE] Error checking cache validity: $e');
      return false;
    }
  }

  /// Get cache size in human readable format
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

