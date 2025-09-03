import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class to provide easy access to Supabase client
class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// Get the Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Get the current user (null if not authenticated)
  User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get auth state stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
