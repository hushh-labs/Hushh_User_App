import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseInit {
  static Future<void> initialize() async {
    // Get credentials from .env file
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env file',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Getter for the Supabase client
  static SupabaseClient get client => Supabase.instance.client;
}
