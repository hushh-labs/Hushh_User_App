import 'package:supabase_flutter/supabase_flutter.dart';
import 'remote_config_service.dart';

class SupabaseInit {
  static SupabaseClient? _serviceClient;

  static Future<void> initialize() async {
    // Get credentials from Remote Config
    final supabaseUrl = RemoteConfigService.supabaseUrl;
    // Use anonymous key for client operations (RLS disabled on table)
    final supabaseAnonKey = RemoteConfigService.supabaseAnonKey;
    // Service role key for storage operations
    final supabaseServiceKey = RemoteConfigService.supabaseServiceRoleKey;

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be set in Remote Config',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    // Initialize service client for storage operations
    if (supabaseServiceKey.isNotEmpty) {
      _serviceClient = SupabaseClient(supabaseUrl, supabaseServiceKey);
    }
  }

  // Getter for the Supabase client (anon key)
  static SupabaseClient get client => Supabase.instance.client;

  // Getter for the service client (service role key)
  static SupabaseClient? get serviceClient => _serviceClient;
}
