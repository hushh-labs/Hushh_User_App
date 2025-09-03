import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/gmail_account_model.dart';
import '../models/gmail_email_model.dart';

abstract class SupabaseGmailDataSource {
  // Gmail Account Operations
  Future<void> createGmailAccount(GmailAccountModel account);
  Future<GmailAccountModel?> getGmailAccount(String userId);
  Future<void> updateGmailAccount(GmailAccountModel account);
  Future<void> deleteGmailAccount(String userId);
  Future<bool> isGmailConnected(String userId);

  // Gmail Email Operations
  Future<void> storeEmails(List<GmailEmailModel> emails);
  Future<List<GmailEmailModel>> getEmails(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  });
  Future<void> deleteEmailsOlderThan(String userId, DateTime date);
  Future<int> getEmailCount(String userId);
  Future<DateTime?> getLastSyncDate(String userId);
  Future<void> updateLastSyncDate(String userId, DateTime syncDate);

  // Sync Settings Operations
  Future<void> updateSyncSettings(String userId, Map<String, dynamic> settings);
  Future<Map<String, dynamic>?> getSyncSettings(String userId);
}

class SupabaseGmailDataSourceImpl implements SupabaseGmailDataSource {
  final SupabaseService _supabaseService;

  static const String _accountsTableName = 'gmail_accounts';
  static const String _emailsTableName = 'gmail_emails';

  SupabaseGmailDataSourceImpl(this._supabaseService);

  SupabaseClient get _client => _supabaseService.client;

  // Gmail Account Operations
  @override
  Future<void> createGmailAccount(GmailAccountModel account) async {
    try {
      final now = DateTime.now();
      final accountData = account.toJson()
        ..['created_at'] = now.toIso8601String()
        ..['updated_at'] = now.toIso8601String();

      await _client.from(_accountsTableName).insert(accountData);
    } catch (e) {
      throw Exception('Failed to create Gmail account in Supabase: $e');
    }
  }

  @override
  Future<GmailAccountModel?> getGmailAccount(String userId) async {
    try {
      final response = await _client
          .from(_accountsTableName)
          .select()
          .eq('userId', userId)
          .maybeSingle();

      if (response != null) {
        return GmailAccountModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get Gmail account from Supabase: $e');
    }
  }

  @override
  Future<void> updateGmailAccount(GmailAccountModel account) async {
    try {
      final now = DateTime.now();
      final accountData = account.toJson()
        ..['updated_at'] = now.toIso8601String()
        ..remove('created_at'); // Don't update created_at

      await _client
          .from(_accountsTableName)
          .update(accountData)
          .eq('userId', account.userId);
    } catch (e) {
      throw Exception('Failed to update Gmail account in Supabase: $e');
    }
  }

  @override
  Future<void> deleteGmailAccount(String userId) async {
    try {
      // Delete account (emails will be cascade deleted due to foreign key)
      await _client.from(_accountsTableName).delete().eq('userId', userId);
    } catch (e) {
      throw Exception('Failed to delete Gmail account from Supabase: $e');
    }
  }

  @override
  Future<bool> isGmailConnected(String userId) async {
    try {
      final response = await _client
          .from(_accountsTableName)
          .select('isConnected')
          .eq('userId', userId)
          .maybeSingle();

      return response?['isConnected'] == true;
    } catch (e) {
      throw Exception('Failed to check Gmail connection status: $e');
    }
  }

  // Gmail Email Operations
  @override
  Future<void> storeEmails(List<GmailEmailModel> emails) async {
    if (emails.isEmpty) return;

    try {
      final emailData = emails.map((email) => email.toJson()).toList();

      // Use upsert to handle duplicate message IDs
      await _client
          .from(_emailsTableName)
          .upsert(emailData, onConflict: 'userId,messageId');
    } catch (e) {
      throw Exception('Failed to store emails in Supabase: $e');
    }
  }

  @override
  Future<List<GmailEmailModel>> getEmails(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      // Build the query string with filters
      String selectQuery = '*';

      final response = await _client
          .from(_emailsTableName)
          .select(selectQuery)
          .eq('userId', userId)
          .order('receivedAt', ascending: false);

      // Filter the results in memory for now
      // TODO: Implement proper date filtering with Supabase query
      var emails = response
          .map<GmailEmailModel>((json) => GmailEmailModel.fromJson(json))
          .toList();

      // Apply date filtering in memory
      if (fromDate != null) {
        emails = emails
            .where(
              (email) =>
                  email.receivedAt.isAfter(fromDate) ||
                  email.receivedAt.isAtSameMomentAs(fromDate),
            )
            .toList();
      }

      if (toDate != null) {
        emails = emails
            .where(
              (email) =>
                  email.receivedAt.isBefore(toDate) ||
                  email.receivedAt.isAtSameMomentAs(toDate),
            )
            .toList();
      }

      // Apply pagination in memory
      if (offset != null && offset > 0) {
        emails = emails.skip(offset).toList();
      }

      if (limit != null) {
        emails = emails.take(limit).toList();
      }

      return emails;
    } catch (e) {
      throw Exception('Failed to get emails from Supabase: $e');
    }
  }

  @override
  Future<void> deleteEmailsOlderThan(String userId, DateTime date) async {
    try {
      await _client
          .from(_emailsTableName)
          .delete()
          .eq('userId', userId)
          .lt('receivedAt', date.toIso8601String());
    } catch (e) {
      throw Exception('Failed to delete old emails from Supabase: $e');
    }
  }

  @override
  Future<int> getEmailCount(String userId) async {
    try {
      final response = await _client
          .from(_emailsTableName)
          .select('id')
          .eq('userId', userId)
          .count();

      return response.count;
    } catch (e) {
      throw Exception('Failed to get email count from Supabase: $e');
    }
  }

  @override
  Future<DateTime?> getLastSyncDate(String userId) async {
    try {
      final response = await _client
          .from(_accountsTableName)
          .select('lastSyncAt')
          .eq('userId', userId)
          .maybeSingle();

      if (response?['lastSyncAt'] != null) {
        return DateTime.parse(response!['lastSyncAt']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get last sync date from Supabase: $e');
    }
  }

  @override
  Future<void> updateLastSyncDate(String userId, DateTime syncDate) async {
    try {
      await _client
          .from(_accountsTableName)
          .update({
            'lastSyncAt': syncDate.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('userId', userId);
    } catch (e) {
      throw Exception('Failed to update last sync date in Supabase: $e');
    }
  }

  @override
  Future<void> updateSyncSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _client
          .from(_accountsTableName)
          .update({
            'syncSettings': settings,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('userId', userId);
    } catch (e) {
      throw Exception('Failed to update sync settings in Supabase: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getSyncSettings(String userId) async {
    try {
      final response = await _client
          .from(_accountsTableName)
          .select('syncSettings')
          .eq('userId', userId)
          .maybeSingle();

      return response?['syncSettings'] as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get sync settings from Supabase: $e');
    }
  }
}
