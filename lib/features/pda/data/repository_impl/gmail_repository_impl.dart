import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/gmail_account.dart';
import '../../domain/entities/gmail_email.dart';
import '../../domain/repositories/gmail_repository.dart';
import '../data_sources/supabase_gmail_datasource.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/utils/env_utils.dart';

class GmailRepositoryImpl implements GmailRepository {
  final SupabaseGmailDataSource _dataSource;
  // Stream controllers for real-time updates
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<List<GmailEmail>> _emailsController =
      StreamController<List<GmailEmail>>.broadcast();

  GmailRepositoryImpl(this._dataSource);

  // Get Supabase URL and key from environment
  String get _supabaseUrl {
    const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://biiqwforuvzgubrrkfgq.supabase.co');
    return dotenv.env['SUPABASE_URL'] ?? 'https://biiqwforuvzgubrrkfgq.supabase.co';
  }
  String get _supabaseKey {
    const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  @override
  Future<bool> connectGmail(
    String userId, {
    required String accessToken,
    String? refreshToken,
    String? idToken,
    required String email,
    required List<String> scopes,
  }) async {
    try {
      // Check if Gmail is already connected
      final isAlreadyConnected = await isGmailConnected(userId);
      if (isAlreadyConnected) {
        print('✅ [GMAIL REPO] Gmail already connected for user: $userId');
        _connectionStatusController.add(true);
        return true;
      }

      // Connect Gmail using OAuth exchange
      print('🔄 [GMAIL REPO] Connecting Gmail with OAuth credentials');
      final response = await http.post(
        Uri.parse('${_supabaseUrl}/functions/v1/gmail-oauth-exchange'),
        headers: {
          'Authorization': 'Bearer ${_supabaseKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'serverAuthCode': accessToken, // This should be the server auth code
          'idToken': idToken,
          'email': email,
          'scopes': scopes,
        }),
      );

      if (response.statusCode == 200) {
        _connectionStatusController.add(true);
        print('✅ [GMAIL REPO] Gmail connected successfully');
        return true;
      } else {
        print('❌ [GMAIL REPO] OAuth exchange failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ [GMAIL REPO] Error calling OAuth exchange: $e');
      return false;
    }
  }

  @override
  Future<bool> disconnectGmail(String userId) async {
    try {
      await _dataSource.deleteGmailAccount(userId);
      _connectionStatusController.add(false);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isGmailConnected(String userId) async {
    try {
      return await _dataSource.isGmailConnected(userId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<GmailAccount?> getGmailAccount(String userId) async {
    try {
      final accountModel = await _dataSource.getGmailAccount(userId);
      return accountModel?.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> syncEmails(String userId, SyncOptions syncOptions) async {
    try {
      // Call Supabase Edge Function to sync emails with date range
      final url = '$_supabaseUrl/functions/v1/gmail-sync-with-date-range';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseKey',
        },
        body: json.encode({
          'userId': userId,
          'startDate': syncOptions.startDate.toIso8601String(),
          'endDate': syncOptions.endDate.toIso8601String(),
          'syncSettings': syncOptions.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;

        if (success) {
          // Update last sync date
          await _dataSource.updateLastSyncDate(userId, DateTime.now());
          // Update sync settings
          await _dataSource.updateSyncSettings(userId, syncOptions.toJson());

          // Notify listeners
          _notifyEmailsUpdated(userId);
        }

        return success;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> syncNewEmails(String userId) async {
    try {
      // Call Supabase Edge Function for incremental sync
      final url = '$_supabaseUrl/functions/v1/gmail-sync-incremental';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseKey',
        },
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;

        if (success) {
          await _dataSource.updateLastSyncDate(userId, DateTime.now());
          _notifyEmailsUpdated(userId);
        }

        return success;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<GmailEmail>> getEmails(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final emailModels = await _dataSource.getEmails(
        userId,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );

      return emailModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> updateSyncSettings(
    String userId,
    SyncOptions syncOptions,
  ) async {
    try {
      await _dataSource.updateSyncSettings(userId, syncOptions.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SyncOptions?> getSyncSettings(String userId) async {
    try {
      final settings = await _dataSource.getSyncSettings(userId);
      if (settings != null) {
        return SyncOptions.fromJson(settings);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<DateTime?> getLastSyncDate(String userId) async {
    try {
      return await _dataSource.getLastSyncDate(userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> getEmailCount(String userId) async {
    try {
      return await _dataSource.getEmailCount(userId);
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> deleteOldEmails(String userId, DateTime beforeDate) async {
    try {
      await _dataSource.deleteEmailsOlderThan(userId, beforeDate);
      _notifyEmailsUpdated(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  @override
  Stream<List<GmailEmail>> getEmailsStream(String userId) {
    // For real-time updates, you might want to implement Supabase real-time subscriptions
    // For now, return the broadcast stream
    return _emailsController.stream;
  }

  Future<void> _notifyEmailsUpdated(String userId) async {
    final emails = await getEmails(userId); // No limit = get all emails
    _emailsController.add(emails);
  }

  void dispose() {
    _connectionStatusController.close();
    _emailsController.close();
  }
}
