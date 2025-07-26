// Firebase initialization helper
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseInit {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      rethrow;
    }
  }

  static Future<void> initializeWithOptions({
    required FirebaseOptions options,
  }) async {
    try {
      await Firebase.initializeApp(options: options);
      debugPrint('Firebase initialized with custom options');
    } catch (e) {
      debugPrint('Failed to initialize Firebase with custom options: $e');
      rethrow;
    }
  }
}
