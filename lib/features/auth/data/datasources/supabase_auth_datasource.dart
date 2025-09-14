import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_card.dart';
import '../models/user_card_model.dart';
import '../../../../core/services/supabase_service.dart';

abstract class SupabaseAuthDataSource {
  Future<void> createUserCard(UserCard userCard);
  Future<UserCard?> getUserCard(String userId);
  Future<void> updateUserCard(UserCard userCard);
  Future<bool> doesUserCardExist(String userId);
  Future<void> deleteUserCard(String userId);

  // Additional user data methods (for phone number, etc.)
  Future<void> createUserData(String userId, Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData(String userId);
  Future<void> updateUserData(String userId, Map<String, dynamic> userData);

  // Account deletion methods
  Future<void> deleteUserData(String userId);
  Future<void> deleteAllUserDataFromAllTables(String userId);
}

class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  final SupabaseService _supabaseService;

  // Table name in Supabase - matching Firebase collection name for consistency
  static const String _tableName = 'hush_users';

  SupabaseAuthDataSourceImpl(this._supabaseService);

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<void> createUserCard(UserCard userCard) async {
    try {
      final now = DateTime.now();
      final cardData = userCard.toJson()
        // Use snake_case for Supabase table columns
        ..['created_at'] = now.toIso8601String()
        ..['updated_at'] = now.toIso8601String()
        // Remove fields not needed in Supabase
        ..remove('id')
        ..remove('videoUrl')
        // Remove camelCase versions if they exist from Firebase
        ..remove('createdAt')
        ..remove('updatedAt');

      await _client.from(_tableName).insert(cardData);
    } catch (e) {
      throw Exception('Failed to create user card in Supabase: $e');
    }
  }

  @override
  Future<UserCard?> getUserCard(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('userId', userId)
          .maybeSingle();

      if (response != null) {
        // Add back the 'id' field for consistency with domain entity
        final data = Map<String, dynamic>.from(response);
        data['id'] = data['userId'];
        // Convert snake_case to camelCase for consistency with Firebase
        data['createdAt'] = data['created_at'];
        data['updatedAt'] = data['updated_at'];
        return UserCardModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user card from Supabase: $e');
    }
  }

  @override
  Future<void> updateUserCard(UserCard userCard) async {
    try {
      final now = DateTime.now();
      final cardData = userCard.toJson()
        ..['updated_at'] = now.toIso8601String()
        // Remove fields that shouldn't be updated or not needed in Supabase
        ..remove('id')
        ..remove('created_at')
        ..remove('videoUrl');

      await _client
          .from(_tableName)
          .update(cardData)
          .eq('userId', userCard.userId);
    } catch (e) {
      throw Exception('Failed to update user card in Supabase: $e');
    }
  }

  @override
  Future<bool> doesUserCardExist(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('userId')
          .eq('userId', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check user card existence in Supabase: $e');
    }
  }

  @override
  Future<void> deleteUserCard(String userId) async {
    try {
      await _client.from(_tableName).delete().eq('userId', userId);
    } catch (e) {
      throw Exception('Failed to delete user card from Supabase: $e');
    }
  }

  @override
  Future<void> createUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final now = DateTime.now();
      // Filter out camelCase timestamp fields if they exist
      final filteredUserData = Map<String, dynamic>.from(userData)
        ..remove('createdAt')
        ..remove('updatedAt');

      final data = {
        'userId': userId,
        ...filteredUserData,
        // Use snake_case for Supabase table columns
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _client.from(_tableName).insert(data);
    } catch (e) {
      throw Exception('Failed to create user data in Supabase: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('userId', userId)
          .maybeSingle();

      if (response != null) {
        // Convert snake_case to camelCase for consistency with Firebase
        final data = Map<String, dynamic>.from(response);
        data['createdAt'] = data['created_at'];
        data['updatedAt'] = data['updated_at'];
        data.remove('created_at');
        data.remove('updated_at');
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data from Supabase: $e');
    }
  }

  @override
  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final now = DateTime.now();
      final data = {...userData, 'updated_at': now.toIso8601String()};
      // Remove fields that shouldn't be updated
      data.remove('userId');
      data.remove('created_at');
      // Remove camelCase timestamp fields if they exist from Firebase
      data.remove('createdAt');
      data.remove('updatedAt');

      await _client.from(_tableName).update(data).eq('userId', userId);
    } catch (e) {
      throw Exception('Failed to update user data in Supabase: $e');
    }
  }

  @override
  Future<void> deleteUserData(String userId) async {
    try {
      await _client.from(_tableName).delete().eq('userId', userId);
    } catch (e) {
      throw Exception('Failed to delete user data from Supabase: $e');
    }
  }

  @override
  Future<void> deleteAllUserDataFromAllTables(String userId) async {
    try {
      print(
        '🗑️ [SUPABASE] Starting comprehensive user data deletion for: $userId',
      );

      // List of all tables that contain user data (excluding micro_prompt_questions)
      final List<Map<String, String>> tablesToDelete = [
        // Core user data
        {'table': 'hush_users', 'field': 'userId'},

        // Gmail data
        {'table': 'gmail_accounts', 'field': 'userId'},
        {'table': 'gmail_emails', 'field': 'userId'},

        // Google Calendar data
        {'table': 'google_calendar_events', 'field': 'userId'},
        {'table': 'google_calendar_attendees', 'field': 'userId'},

        // Google Drive data
        {'table': 'DriveFile', 'field': 'user_id'},
        {'table': 'google_drive_accounts', 'field': 'user_id'},

        // Google Meet data
        {'table': 'google_meet_accounts', 'field': 'user_id'},
        {'table': 'google_meet_calendar_links', 'field': 'user_id'},
        {'table': 'google_meet_conferences', 'field': 'user_id'},
        {'table': 'google_meet_participants', 'field': 'user_id'},
        {'table': 'google_meet_recordings', 'field': 'user_id'},
        {'table': 'google_meet_spaces', 'field': 'user_id'},
        {'table': 'google_meet_transcripts', 'field': 'user_id'},

        // PDA context data
        {'table': 'pda_context', 'field': 'userId'},
        {'table': 'pda_meeting_context', 'field': 'userId'},

        // Micro prompts data (excluding micro_prompt_questions which is global)
        {'table': 'user_app_state', 'field': 'userId'},
        {'table': 'user_micro_prompt_profile', 'field': 'userId'},
        {'table': 'user_micro_prompt_responses', 'field': 'userId'},
        {'table': 'user_micro_prompt_schedule', 'field': 'userId'},
        {'table': 'user_next_micro_prompt', 'field': 'userId'},

        // Vault data
        {'table': 'vault_documents', 'field': 'user_id'},

        // Drive views (treating as tables)
        {'table': 'v_drive_account_status', 'field': 'user_id'},
        {'table': 'v_drive_files_by_user', 'field': 'user_id'},
      ];

      // Delete from each table
      for (final tableInfo in tablesToDelete) {
        try {
          final result = await _client
              .from(tableInfo['table']!)
              .delete()
              .eq(tableInfo['field']!, userId);

          print('✅ [SUPABASE] Deleted from ${tableInfo['table']}');
        } catch (e) {
          // Log error but continue with other tables
          print(
            '⚠️ [SUPABASE] Failed to delete from ${tableInfo['table']}: $e',
          );
        }
      }

      print('🎯 [SUPABASE] Comprehensive user data deletion completed');
    } catch (e) {
      throw Exception('Failed to delete all user data from Supabase: $e');
    }
  }
}
