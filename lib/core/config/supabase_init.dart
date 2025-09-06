import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseInit {
  static SupabaseClient? _serviceClient;

  static Future<void> initialize() async {
    // Get credentials from .env file
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    // Use anonymous key for client operations (RLS disabled on table)
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    // Service role key for storage operations
    final supabaseServiceKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env file',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    // Initialize service client for storage operations
    if (supabaseServiceKey != null) {
      _serviceClient = SupabaseClient(supabaseUrl, supabaseServiceKey);
    }
  }

  // Getter for the Supabase client (anon key)
  static SupabaseClient get client => Supabase.instance.client;

  // Getter for the service client (service role key)
  static SupabaseClient? get serviceClient => _serviceClient;
}
