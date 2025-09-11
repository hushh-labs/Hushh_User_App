import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hushh_user_app/features/pda/domain/repositories/gmail_repository.dart';
import 'package:hushh_user_app/features/pda/domain/entities/gmail_email.dart';
import 'package:hushh_user_app/features/pda/presentation/widgets/gmail_sync_dialog.dart';
import 'package:hushh_user_app/shared/services/gmail_connector_service.dart';
import 'package:hushh_user_app/features/pda/data/services/supabase_gmail_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class GmailPage extends StatefulWidget {
  const GmailPage({super.key});

  @override
  State<GmailPage> createState() => _GmailPageState();
}

class _GmailPageState extends State<GmailPage> {
  final GetIt _getIt = GetIt.instance;
  final GmailConnectorService _connector = GmailConnectorService();
  final SupabaseGmailService _supabaseGmailService = SupabaseGmailService();

  bool _loading = false;
  bool _connected = false;
  String? _error;
  List<GmailEmail> _emails = [];

  // ChatGPT-esque monochrome theme
  static const Color bg = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF000000);
  static const Color hint = Color(0xFF666666);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color border = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Use the same connectivity check used across the app (Supabase-backed)
      final isConnected = await _supabaseGmailService.isGmailConnected();
      _connected = isConnected;
      if (_connected) {
        await _loadEmails();
      }
    } catch (e) {
      _error = 'Failed to initialize Gmail: $e';
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadEmails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = _getIt<GmailRepository>();
      final list = await repo.getEmails(user.uid, limit: 50);
      setState(() => _emails = list);
    } catch (e) {
      setState(() => _error = 'Failed to load emails: $e');
    }
  }

  Future<void> _connect() async {
    setState(() => _loading = true);
    final res = await _connector.connectGmail();
    setState(() {
      _loading = false;
      _connected = res.isSuccess;
      _error = res.isSuccess ? null : res.error;
    });
    if (_connected) {
      await _loadEmails();
    }
  }

  Future<void> _disconnect() async {
    setState(() => _loading = true);
    final res = await _connector.disconnectGmail();
    setState(() {
      _loading = false;
      _connected = !res.isSuccess;
      if (res.isSuccess) _emails = [];
    });
  }

  Future<void> _openSyncDialog() async {
    await showGmailSyncDialog(
      context,
      onSyncSelected: (options) async {
        // Delegate to repository use case through SupabaseGmailService path
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          // Use case is wired in DI via GmailModule
          final repo = _getIt<GmailRepository>();
          await repo.syncEmails(user.uid, options);
          await _loadEmails();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: text),
        ),
        title: const Text(
          'Gmail',
          style: TextStyle(
            color: text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _bootstrap,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: text),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: border),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _connected
          ? FloatingActionButton.extended(
              onPressed: _openSyncDialog,
              backgroundColor: text,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.sync),
              label: const Text('Sync'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError(_error!);
    }
    if (!_connected) {
      return _buildConnectCard();
    }
    if (_emails.isEmpty) {
      return _buildEmpty();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emails.length,
      itemBuilder: (context, index) => _emailCard(_emails[index]),
    );
  }

  Widget _buildConnectCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect Gmail',
              style: TextStyle(
                color: text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your Gmail to view recent emails and enable PDA context.',
              style: TextStyle(color: hint),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: text,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Connect Gmail'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mail_outline, size: 64, color: hint),
          const SizedBox(height: 12),
          const Text(
            'No recent emails found',
            style: TextStyle(color: hint, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openSyncDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: text,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Start Sync'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _disconnect,
            child: const Text('Disconnect', style: TextStyle(color: hint)),
          ),
        ],
      ),
    );
  }

  Widget _emailCard(GmailEmail email) {
    return InkWell(
      onTap: () => _openInEmailApp(email),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    email.fromName ?? email.fromEmail ?? 'Unknown sender',
                    style: const TextStyle(
                      color: text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  email.formattedDate,
                  style: const TextStyle(color: hint, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    email.subject ?? '(No subject)',
                    style: const TextStyle(
                      color: text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (email.isImportant)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.star, size: 16, color: text),
                  ),
              ],
            ),
            if ((email.snippet ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  email.snippet!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: hint, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInEmailApp(GmailEmail email) async {
    final messageId = email.messageId;
    final Uri gmailDeepSearch = Uri.parse(
      'googlegmail://search?query=rfc822msgid:$messageId',
    ); // Gmail app search
    final Uri gmailDeepSearchAlt = Uri.parse(
      'googlegmail://search?q=rfc822msgid:$messageId',
    );
    final Uri webUrl = Uri.parse(
      'https://mail.google.com/mail/u/0/#search/rfc822msgid%3A$messageId',
    );

    try {
      if (await canLaunchUrl(gmailDeepSearch)) {
        await launchUrl(gmailDeepSearch, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(gmailDeepSearchAlt)) {
        await launchUrl(
          gmailDeepSearchAlt,
          mode: LaunchMode.externalApplication,
        );
        return;
      }
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback: open generic mail app compose with subject (view not supported)
      final Uri mailto = Uri.parse(
        'mailto:?subject=${Uri.encodeComponent(email.subject ?? '')}',
      );
      await launchUrl(mailto, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _bootstrap,
            style: ElevatedButton.styleFrom(
              backgroundColor: text,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class GmailEmailDetailPage extends StatelessWidget {
  final GmailEmail email;
  const GmailEmailDetailPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final hasHtml = (email.bodyHtml != null && email.bodyHtml!.isNotEmpty);
    final hasText = (email.bodyText != null && email.bodyText!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          email.subject ?? '(No subject)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email.fromName ?? email.fromEmail ?? 'Unknown sender',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (hasHtml)
                Html(data: email.bodyHtml!)
              else if (hasText)
                Text(email.bodyText!)
              else
                const Text('No content available'),
            ],
          ),
        ),
      ),
    );
  }
}
