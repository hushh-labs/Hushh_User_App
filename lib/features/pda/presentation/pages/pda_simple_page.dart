import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get_it/get_it.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_message.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/send_message_use_case.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/get_messages_use_case.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/clear_messages_use_case.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hushh_user_app/features/pda/presentation/components/pda_loading_animation.dart';

import '../../data/services/supabase_gmail_service.dart';
import '../../data/services/simple_linkedin_service.dart';
import '../widgets/gmail_sync_dialog.dart';
import '../../domain/repositories/gmail_repository.dart';
import '../../domain/repositories/google_meet_repository.dart';
import '../../data/data_sources/google_meet_supabase_data_source_impl.dart';
import 'google_meet_oauth_webview.dart';

import 'package:hushh_user_app/shared/utils/app_local_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hushh_user_app/core/routing/route_paths.dart';

class PdaSimplePage extends StatefulWidget {
  const PdaSimplePage({super.key});

  @override
  State<PdaSimplePage> createState() => _PdaSimplePageState();
}

class _PdaSimplePageState extends State<PdaSimplePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GetIt _getIt = GetIt.instance;
  final SupabaseGmailService _supabaseGmailService = SupabaseGmailService();
  final SupabaseLinkedInService _supabaseLinkedInService =
      SupabaseLinkedInService();

  List<PdaMessage> _messages = [];
  bool _isLoadingMessages =
      false; // Separate loading state for initial messages
  bool _isSendingMessage = false; // Separate loading state for sending
  bool _isGmailConnected = false; // Gmail connection status
  bool _isConnectingGmail = false; // Gmail connection loading state
  bool _isLinkedInConnected = false; // LinkedIn connection status
  bool _isConnectingLinkedIn = false; // LinkedIn connection loading state
  bool _isGoogleMeetConnected = false; // Google Meet connection status
  bool _isConnectingGoogleMeet = false; // Google Meet connection loading state
  String? _error;

  // Single source of truth for suggestions - Hushh app specific options
  final List<Map<String, dynamic>> _suggestions = const [
    {'text': 'How do I find products?', 'icon': Icons.search_outlined},
    {'text': 'Tell me about agents', 'icon': Icons.person_outline},
    {
      'text': 'How do I add items to cart?',
      'icon': Icons.shopping_cart_outlined,
    },
    {'text': 'What are Hushh features?', 'icon': Icons.lightbulb_outline},
    {'text': 'Help me with my account', 'icon': Icons.account_circle_outlined},
  ];

  // Define some brand colors
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);
  static const Color lightGreyBackground = Color(0xFFF9F9F9);

  static const Color chatBubblePda = Color(0xFFFFFFFF); // White for PDA
  static const Color borderColor = Color(0xFFE0E0E0); // Lighter border

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkGmailConnectionStatus();
    _checkLinkedInConnectionStatus();
    _checkGoogleMeetConnectionStatus();
    _messageController.addListener(_updateSendButtonState);
  }

  @override
  void didUpdateWidget(covariant PdaSimplePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToBottom();
  }

  // New method to update send button state (enable/disable)
  void _updateSendButtonState() {
    setState(() {}); // Rebuild to update button state based on text controller
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _error = 'User not authenticated';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingMessages = true;
        _error = null;
      });
    }

    try {
      final getMessagesUseCase = _getIt<GetMessagesUseCase>();
      final result = await getMessagesUseCase(currentUser.uid);

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _error = failure.toString();
              _isLoadingMessages = false;
            });
          }
        },
        (messages) {
          if (mounted) {
            setState(() {
              _messages = messages;
              _isLoadingMessages = false;
            });
            _scrollToBottom();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _sendMessage({String? predefinedMessage}) async {
    final message = predefinedMessage ?? _messageController.text.trim();
    if (message.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _error = 'User not authenticated';
      });
      return;
    }

    // Add user message immediately for optimistic UI
    setState(() {
      _messages.add(
        PdaMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          hushhId:
              AppLocalStorage.hushhId ??
              'user-${DateTime.now().millisecondsSinceEpoch}',
          content: message,
          isFromUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear(); // Clear input field
      _isSendingMessage = true; // Set sending state
      _error = null; // Clear previous errors
    });
    _scrollToBottom(); // Scroll to show new user message

    try {
      final sendMessageUseCase = _getIt<PdaSendMessageUseCase>();
      final result = await sendMessageUseCase(
        hushhId: currentUser.uid,
        message: message,
        context: _messages, // Pass full context for AI
      );

      result.fold(
        (failure) {
          setState(() {
            // Add a failure message or revert the last user message
            _error = 'Failed to send: ${failure.toString()}';
            // Optionally, remove the last user message if sending truly failed server-side
            // _messages.removeLast();
            _isSendingMessage = false;
          });
        },
        (aiMessage) {
          setState(() {
            // Replace the last (user's) message with the AI's full response if needed,
            // or just add the AI's response after the user's message.
            // For a continuous chat, simply add the AI's response.
            _messages.add(aiMessage);
            _isSendingMessage = false;
          });
          _scrollToBottom();
        },
      );
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: ${e.toString()}';
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _clearMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final clearMessagesUseCase = _getIt<ClearMessagesUseCase>();
      await clearMessagesUseCase(currentUser.uid);
      setState(() {
        _messages.clear();
        _error = null; // Clear any previous errors
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to clear messages: ${e.toString()}';
      });
    }
  }

  void _showClearConfirmation() {
    showCupertinoDialog(
      // Use Cupertino style for a more modern feel
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all messages? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _clearMessages();
            },
            isDestructiveAction: true, // Red text for destructive action
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// Check Gmail connection status on page load
  Future<void> _checkGmailConnectionStatus() async {
    try {
      final isConnected = await _supabaseGmailService.isGmailConnected();
      setState(() {
        _isGmailConnected = isConnected;
      });

      // Check if sync is needed on startup
      if (isConnected) {
        final needsSync = await _supabaseGmailService.checkSyncNeeded();
        if (needsSync) {
          debugPrint('🔄 [PDA] Gmail sync needed on startup');
          // Perform automatic sync for new emails
          _triggerQuickSync();
        }
      }
    } catch (e) {
      debugPrint('Error checking Gmail connection status: $e');
    }
  }

  /// Check LinkedIn connection status on page load
  Future<void> _checkLinkedInConnectionStatus() async {
    try {
      final isConnected = await _supabaseLinkedInService.isLinkedInConnected();
      setState(() {
        _isLinkedInConnected = isConnected;
      });

      debugPrint('🔗 [PDA] LinkedIn connection status: $isConnected');
    } catch (e) {
      debugPrint('❌ [PDA] Error checking LinkedIn connection: $e');
    }
  }

  /// Handle Gmail connection
  Future<void> _onConnectGmailPressed() async {
    if (_isGmailConnected) {
      // If already connected, show sync options
      _showGmailOptionsDialog();
      return;
    }

    setState(() {
      _isConnectingGmail = true;
      _error = null;
    });

    try {
      // First connect using the new Supabase service
      final result = await _supabaseGmailService.connectGmail();

      if (result.isSuccess) {
        setState(() {
          _isGmailConnected = true;
          _isConnectingGmail = false;
        });

        // Show success message and sync dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gmail connected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Show sync options dialog
          _showInitialSyncDialog();
        }
      } else {
        setState(() {
          _isConnectingGmail = false;
          _error = 'Failed to connect Gmail: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _isConnectingGmail = false;
        _error = 'An error occurred while connecting Gmail: $e';
      });
    }
  }

  /// Show initial sync dialog after connection
  Future<void> _showInitialSyncDialog() async {
    await showGmailSyncDialog(
      context,
      onSyncSelected: (syncOptions) async {
        await _triggerGmailSyncWithOptions(syncOptions);
      },
    );
  }

  /// Show Gmail options when already connected
  void _showGmailOptionsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Gmail Connected'),
        content: const Text(
          'Your Gmail is already connected. What would you like to do?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _showSyncOptionsDialog();
            },
            child: const Text('Sync Again'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _triggerQuickSync();
            },
            child: const Text('Quick Sync'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _disconnectGmail();
            },
            isDestructiveAction: true,
            child: const Text('Disconnect'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Show sync options dialog for existing connections
  Future<void> _showSyncOptionsDialog() async {
    await showGmailSyncDialog(
      context,
      onSyncSelected: (syncOptions) async {
        await _triggerGmailSyncWithOptions(syncOptions);
      },
    );
  }

  /// Trigger Gmail sync with options
  Future<void> _triggerGmailSyncWithOptions(SyncOptions syncOptions) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔄 Syncing Gmail (${syncOptions.duration.displayName})...',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final result = await _supabaseGmailService.syncEmails(syncOptions);

      if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Gmail sync completed! Stored ${result.messagesCount} emails.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Gmail sync failed: ${result.error}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error during Gmail sync: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildVaultButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          context.push(RoutePaths.vault);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPurple,
          side: BorderSide(
            color: primaryPurple.withValues(alpha: 0.5),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        icon: Icon(Icons.folder_open_rounded, color: primaryPurple, size: 20),
        label: const Text(
          'Vault',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Trigger quick sync for new emails
  Future<void> _triggerQuickSync() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Quick syncing new emails...'),
          duration: Duration(seconds: 2),
        ),
      );

      final result = await _supabaseGmailService.syncGmailNow();

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Quick sync completed! Found ${result.messagesCount} total emails.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Quick sync failed: ${result.error}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error during quick sync: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Disconnect Gmail
  Future<void> _disconnectGmail() async {
    try {
      final result = await _supabaseGmailService.disconnectGmail();

      if (result.isSuccess) {
        setState(() {
          _isGmailConnected = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gmail disconnected successfully'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect Gmail: ${result.error}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disconnecting Gmail: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle LinkedIn connection
  Future<void> _onConnectLinkedInPressed() async {
    if (_isLinkedInConnected) {
      // If already connected, show LinkedIn options
      _showLinkedInOptionsDialog();
      return;
    }

    setState(() {
      _isConnectingLinkedIn = true;
      _error = null;
    });

    try {
      final result = await _supabaseLinkedInService.connectLinkedIn();

      if (result.success) {
        setState(() {
          _isLinkedInConnected = true;
          _isConnectingLinkedIn = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ LinkedIn connected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isConnectingLinkedIn = false;
          _error = 'Failed to connect LinkedIn: ${result.message}';
        });
      }
    } catch (e) {
      setState(() {
        _isConnectingLinkedIn = false;
        _error = 'An error occurred while connecting LinkedIn: $e';
      });
    }
  }

  /// Show LinkedIn options when already connected
  void _showLinkedInOptionsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('LinkedIn Connected'),
        content: const Text(
          'Your LinkedIn is already connected. What would you like to do?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _triggerLinkedInSync();
            },
            child: const Text('Sync Data'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _disconnectLinkedIn();
            },
            isDestructiveAction: true,
            child: const Text('Disconnect'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Trigger LinkedIn data sync
  Future<void> _triggerLinkedInSync() async {
    try {
      // Use comprehensive sync options
      const syncOptions = LinkedInSyncOptions(
        includeProfile: true,
        includePosts: true,
      );

      final result = await _supabaseLinkedInService.syncLinkedInData(
        syncOptions,
      );

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ LinkedIn data synced successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync LinkedIn data. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error syncing LinkedIn data: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Disconnect LinkedIn account
  Future<void> _disconnectLinkedIn() async {
    try {
      final result = await _supabaseLinkedInService.disconnectLinkedIn();

      if (result) {
        setState(() {
          _isLinkedInConnected = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('LinkedIn disconnected successfully'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to disconnect LinkedIn'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disconnecting LinkedIn: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Check Google Meet connection status on page load
  Future<void> _checkGoogleMeetConnectionStatus() async {
    try {
      final googleMeetRepo = _getIt<GoogleMeetRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final isConnected = await googleMeetRepo.isGoogleMeetConnected(
        currentUser.uid,
      );
      setState(() {
        _isGoogleMeetConnected = isConnected;
      });

      debugPrint('📅 [PDA] Google Meet connection status: $isConnected');
    } catch (e) {
      debugPrint('❌ [PDA] Error checking Google Meet connection: $e');
    }
  }

  /// Handle Google Meet connection
  Future<void> _onConnectGoogleMeetPressed() async {
    if (_isGoogleMeetConnected) {
      // If already connected, show Google Meet options
      _showGoogleMeetOptionsDialog();
      return;
    }

    setState(() {
      _isConnectingGoogleMeet = true;
      _error = null;
    });

    try {
      final googleMeetDataSource = GoogleMeetSupabaseDataSourceImpl();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isConnectingGoogleMeet = false;
        });
        return;
      }

      // Get OAuth URL from the data source
      await googleMeetDataSource.initiateGoogleMeetOAuth(currentUser.uid);

      // This should never be reached as the method throws OAuthUrlException
      setState(() {
        _isConnectingGoogleMeet = false;
        _error = 'Failed to get OAuth URL. Please try again.';
      });
    } catch (e) {
      // Check if this is an OAuth URL exception
      if (e.toString().contains('OAuthUrlException:')) {
        final authUrl = e.toString().replaceFirst('OAuthUrlException: ', '');

        setState(() {
          _isConnectingGoogleMeet = false;
        });

        // Navigate to WebView for OAuth
        try {
          debugPrint('🌐 [GOOGLE MEET] Opening WebView for OAuth: $authUrl');

          final result = await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder: (context) => GoogleMeetOAuthWebView(
                oauthUrl: authUrl,
                redirectUri:
                    'https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync/callback',
              ),
            ),
          );

          if (result != null) {
            if (result['success'] == true) {
              final authCode = result['authCode'] as String?;
              if (authCode != null) {
                // Now complete the OAuth flow with the auth code
                await _completeGoogleMeetOAuth(authCode);
              } else {
                setState(() {
                  _error = 'Failed to get authorization code from OAuth flow';
                });
              }
            } else {
              final error = result['error'] as String? ?? 'OAuth failed';
              if (error != 'User cancelled') {
                setState(() {
                  _error = 'OAuth failed: $error';
                });
              }
            }
          }
        } catch (webViewError) {
          debugPrint('❌ [GOOGLE MEET] WebView error: $webViewError');
          setState(() {
            _error = 'Failed to open authentication page: $webViewError';
          });
        }
      } else {
        setState(() {
          _isConnectingGoogleMeet = false;
          _error = 'An error occurred while connecting Google Meet: $e';
        });
      }
    }
  }

  /// Complete Google Meet OAuth flow with auth code
  Future<void> _completeGoogleMeetOAuth(String authCode) async {
    try {
      setState(() {
        _isConnectingGoogleMeet = true;
      });

      final googleMeetRepo = _getIt<GoogleMeetRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Connect Google Meet account with the auth code
      final result = await googleMeetRepo.connectGoogleMeetAccount(
        userId: currentUser.uid,
        authCode: authCode,
      );

      if (result != null) {
        setState(() {
          _isGoogleMeetConnected = true;
          _isConnectingGoogleMeet = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Google Meet connected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isConnectingGoogleMeet = false;
          _error =
              'Failed to complete Google Meet connection. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnectingGoogleMeet = false;
        _error = 'Error completing OAuth: $e';
      });
    }
  }

  /// Show Google Meet options when already connected
  void _showGoogleMeetOptionsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Google Meet Connected'),
        content: const Text(
          'Your Google Meet is already connected. What would you like to do?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _triggerGoogleMeetSync();
            },
            child: const Text('Sync Data'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _disconnectGoogleMeet();
            },
            isDestructiveAction: true,
            child: const Text('Disconnect'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Trigger Google Meet data sync
  Future<void> _triggerGoogleMeetSync() async {
    try {
      final googleMeetRepo = _getIt<GoogleMeetRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Syncing Google Meet data...'),
          duration: Duration(seconds: 2),
        ),
      );

      await googleMeetRepo.syncGoogleMeetData(currentUser.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Google Meet data synced successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error syncing Google Meet data: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Disconnect Google Meet account
  Future<void> _disconnectGoogleMeet() async {
    try {
      final googleMeetRepo = _getIt<GoogleMeetRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await googleMeetRepo.disconnectGoogleMeet(currentUser.uid);

      setState(() {
        _isGoogleMeetConnected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Meet disconnected successfully'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disconnecting Google Meet: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground, // Consistent background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // PDA icon
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology_alt_outlined,
                  size: 24,
                  color: primaryPurple,
                ),
              ),
            ),
            const Text(
              'Hushh PDA',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cleaning_services_outlined,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Clear Chat',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.black54,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Error display - Improved visual
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages list or Welcome Screen
            Expanded(
              child: _isLoadingMessages && _messages.isEmpty
                  ? PdaLoadingAnimation(
                      isLoading: _isLoadingMessages,
                      onAnimationComplete: () {
                        // Animation completed, but we keep loading until messages are actually loaded
                        // The loading state will be updated in _loadMessages()
                      },
                    )
                  : _messages.isEmpty
                  ? _buildWelcomeScreen()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildChatMessageBubble(message);
                      },
                    ),
            ),

            // Suggested Questions only when chat is empty or near empty for initial prompts
            if (_messages.length <= 2 &&
                !_isLoadingMessages) // Show suggestions for empty or very new chat
              _buildHorizontalSuggestedQuestions(_suggestions),

            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessageBubble(PdaMessage message) {
    final isUser = message.isFromUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser ? Colors.white : chatBubblePda;
    final textColor = isUser ? Colors.white : Colors.black87;
    final borderColor = isUser
        ? primaryPurple.withValues(alpha: 0.3)
        : _PdaSimplePageState.borderColor; // User gets subtle purple border

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // More vertical padding
      child: Align(
        alignment: alignment,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ), // Max width for bubbles
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ), // More padding
          decoration: BoxDecoration(
            color: isUser ? null : bubbleColor,
            gradient: isUser
                ? const LinearGradient(
                    colors: [
                      Color(0xFFA342FF), // Purple
                      Color(0xFFE54D60), // Pink
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isUser
                  ? const Radius.circular(16)
                  : const Radius.circular(4), // Tail effect
              bottomRight: isUser
                  ? const Radius.circular(4)
                  : const Radius.circular(16), // Tail effect
            ),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), // Subtle shadow
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    height: 1.4, // Better line height
                  ),
                ),
              ),
              if (!isUser &&
                  _isSendingMessage &&
                  message ==
                      _messages
                          .last) // Show typing indicator only for the last PDA message while sending
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!,
                      ),
                    ),
                  ),
                ),
              // Optionally add timestamp here
              // Padding(
              //   padding: const EdgeInsets.only(top: 4.0),
              //   child: Text(
              //     DateFormat('h:mm a').format(message.timestamp),
              //     style: TextStyle(
              //       fontSize: 10,
              //       color: Colors.grey[500],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      // Allow scrolling if content is too large
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // More rounded
              border: Border.all(
                color: Colors.grey[100]!, // Lighter border
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.04,
                  ), // Slightly stronger, but still soft shadow
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient
                Container(
                  padding: const EdgeInsets.all(18), // Larger padding
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryPurple, primaryPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      18,
                    ), // Slightly more rounded than inner padding
                    boxShadow: [
                      // Add shadow to the icon container
                      BoxShadow(
                        color: primaryPurple.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_alt_outlined, // More modern icon
                    size: 36, // Larger icon
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28), // Increased space
                const Text(
                  'Your Hushh Assistant is Here', // More engaging title
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24, // Larger
                    fontWeight: FontWeight.w800, // Bolder
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16), // Increased space
                Text(
                  'I\'m here to help you navigate Hushh, discover products, connect with agents, and make the most of your shopping experience. Ask me anything about the app!', // More direct CTA
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16, // Slightly larger
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                    height: 1.6, // Improved line height
                  ),
                ),
                const SizedBox(height: 20),
                _buildConnectionButtons(),
                const SizedBox(height: 6),
                Text(
                  'for personalised answers',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32), // Increased space
                // Feature highlights with a more refined look
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureItem(
                      Icons.lock_outline_rounded,
                      'Private',
                    ), // 'Secure' -> 'Private' with new icon
                    _buildFeatureItem(
                      Icons.flash_on_rounded,
                      'Instant',
                    ), // 'Fast' -> 'Instant' with new icon
                    _buildFeatureItem(
                      Icons.auto_awesome_rounded,
                      'Smart',
                    ), // Same, new icon
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButtons() {
    return Column(
      children: [
        // Gmail Button
        _buildConnectGmailButton(),
        const SizedBox(height: 8),
        // LinkedIn Button
        _buildConnectLinkedInButton(),
        const SizedBox(height: 8),
        // Google Meet Button
        _buildConnectGoogleMeetButton(),
        const SizedBox(height: 8),
        // Vault Button
        _buildVaultButton(),
      ],
    );
  }

  Widget _buildConnectGmailButton() {
    if (_isGmailConnected) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onConnectGmailPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: const Text(
            'Gmail Connected',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isConnectingGmail ? null : _onConnectGmailPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPurple,
          side: BorderSide(
            color: primaryPurple.withValues(alpha: 0.5),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        icon: _isConnectingGmail
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
                ),
              )
            : Icon(Icons.mail_outline_rounded, color: primaryPurple, size: 20),
        label: Text(
          _isConnectingGmail ? 'Connecting...' : 'Connect Gmail',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildConnectLinkedInButton() {
    if (_isLinkedInConnected) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onConnectLinkedInPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0077B5), // LinkedIn blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: const Text(
            'LinkedIn Connected',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isConnectingLinkedIn ? null : _onConnectLinkedInPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF0077B5), // LinkedIn blue
          side: BorderSide(
            color: Color(0xFF0077B5).withValues(alpha: 0.5),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        icon: _isConnectingLinkedIn
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077B5)),
                ),
              )
            : Icon(
                Icons.work_outline_rounded,
                color: Color(0xFF0077B5),
                size: 20,
              ),
        label: Text(
          _isConnectingLinkedIn ? 'Connecting...' : 'Connect LinkedIn',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildConnectGoogleMeetButton() {
    if (_isGoogleMeetConnected) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onConnectGoogleMeetPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4285F4), // Google blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: const Text(
            'Google Meet Connected',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isConnectingGoogleMeet ? null : _onConnectGoogleMeetPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF4285F4), // Google blue
          side: BorderSide(
            color: Color(0xFF4285F4).withValues(alpha: 0.5),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        icon: _isConnectingGoogleMeet
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                ),
              )
            : Icon(
                Icons.video_call_outlined,
                color: Color(0xFF4285F4),
                size: 20,
              ),
        label: Text(
          _isConnectingGoogleMeet ? 'Connecting...' : 'Connect Google Meet',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryPurple.withValues(
              alpha: 0.1,
            ), // Use a lighter tint of purple
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 24,
            color: primaryPurple,
          ), // Icon color from palette
        ),
        const SizedBox(height: 8), // Increased space
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalSuggestedQuestions(
    List<Map<String, dynamic>> suggestions,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 12), // Adjusted margin
      height: 50, // Slightly reduced height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: 10), // Reduced space
        itemBuilder: (context, i) {
          final s = suggestions[i];
          return InkWell(
            borderRadius: BorderRadius.circular(25), // More rounded
            onTap: () => _sendMessage(
              predefinedMessage: s['text'] as String,
            ), // Send directly
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ), // Adjusted padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: primaryPurple.withValues(alpha: 0.5),
                  width: 1,
                ), // Lighter, more subtle border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05,
                    ), // Subtle shadow
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    s['icon'] as IconData,
                    size: 16, // Slightly smaller icon
                    color: primaryPurple,
                  ),
                  const SizedBox(width: 8), // Reduced space
                  Text(
                    s['text'] as String,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500, // Slightly less bold
                      fontSize: 13, // Slightly smaller font
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    bool isSendButtonEnabled =
        _messageController.text.trim().isNotEmpty && !_isSendingMessage;

    return Container(
      color: Colors.white, // Keep background white for contrast
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        10,
        12,
      ), // Adjust padding for send button
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(30), // More rounded
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.03,
                      ), // Subtle shadow for depth
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...', // More direct hint
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, // Increased horizontal padding
                      vertical: 14, // Increased vertical padding
                    ),
                  ),
                  maxLines: 5, // Allow more lines before scrolling
                  minLines: 1, // Start with one line
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (text) {
                    if (isSendButtonEnabled) {
                      _sendMessage();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button with animated state
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSendButtonEnabled
                    ? const LinearGradient(
                        colors: [primaryPurple, primaryPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null, // No gradient when disabled
                color: isSendButtonEnabled
                    ? null
                    : Colors.grey[300], // Grey when disabled
              ),
              child: IconButton(
                icon: _isSendingMessage
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSendButtonEnabled
                                ? Colors.white
                                : Colors.grey[600]!,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: isSendButtonEnabled
                            ? Colors.white
                            : Colors
                                  .grey[600], // White when active, grey when disabled
                        size: 24,
                      ),
                onPressed: isSendButtonEnabled
                    ? _sendMessage
                    : null, // Disable when not active
                padding: const EdgeInsets.all(14), // Larger touch target
                splashRadius: 24, // Visual feedback on tap
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateSendButtonState);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
