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
import 'google_meet_page.dart';
import '../../domain/repositories/google_drive_repository.dart';
import '../../data/data_sources/google_drive_supabase_data_source_impl.dart';
import '../../data/services/google_drive_context_prewarm_service.dart';

import 'package:hushh_user_app/shared/utils/app_local_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hushh_user_app/core/routing/route_paths.dart';

class PdaChatGptStylePage extends StatefulWidget {
  const PdaChatGptStylePage({super.key});

  @override
  State<PdaChatGptStylePage> createState() => _PdaChatGptStylePageState();
}

class _PdaChatGptStylePageState extends State<PdaChatGptStylePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GetIt _getIt = GetIt.instance;
  final SupabaseGmailService _supabaseGmailService = SupabaseGmailService();
  final SupabaseLinkedInService _supabaseLinkedInService =
      SupabaseLinkedInService();

  List<PdaMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  bool _isGmailConnected = false;
  bool _isConnectingGmail = false;
  bool _isLinkedInConnected = false;
  bool _isConnectingLinkedIn = false;
  bool _isGoogleMeetConnected = false;
  bool _isConnectingGoogleMeet = false;
  bool _isGoogleDriveConnected = false;
  bool _isConnectingGoogleDrive = false;
  String? _error;

  // ChatGPT-style colors (Black and White Theme)
  static const Color darkBackground = Color(0xFF000000);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color sidebarBackground = Color(0xFFFFFFFF); // White sidebar
  static const Color userBubbleColor = Color(0xFF000000); // Black for user
  static const Color assistantBubbleColor = Color(
    0xFFF8F8F8,
  ); // Very light gray
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color textColor = Color(0xFF000000); // Pure black text
  static const Color hintColor = Color(0xFF666666); // Dark gray for hints
  static const Color sidebarTextColor = Color(
    0xFF000000,
  ); // Black text for sidebar

  // Suggestions for empty chat
  final List<Map<String, dynamic>> _suggestions = const [
    {'text': 'How do I find products?', 'icon': Icons.search_outlined},
    {'text': 'Tell me about agents', 'icon': Icons.person_outline},
    {
      'text': 'How do I add items to cart?',
      'icon': Icons.shopping_cart_outlined,
    },
    {'text': 'What are Hushh features?', 'icon': Icons.lightbulb_outline},
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkGmailConnectionStatus();
    _checkLinkedInConnectionStatus();
    _checkGoogleMeetConnectionStatus();
    _checkGoogleDriveConnectionStatus();
    _messageController.addListener(_updateSendButtonState);
  }

  void _updateSendButtonState() {
    setState(() {});
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
      _messageController.clear();
      _isSendingMessage = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final sendMessageUseCase = _getIt<PdaSendMessageUseCase>();
      final result = await sendMessageUseCase(
        hushhId: currentUser.uid,
        message: message,
        context: _messages,
      );

      result.fold(
        (failure) {
          setState(() {
            _error = 'Failed to send: ${failure.toString()}';
            _isSendingMessage = false;
          });
        },
        (aiMessage) {
          setState(() {
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
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to clear messages: ${e.toString()}';
      });
    }
  }

  void _showClearConfirmation() {
    showCupertinoDialog(
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
            isDestructiveAction: true,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // Connection status methods (keeping the same logic as original)
  Future<void> _checkGmailConnectionStatus() async {
    try {
      final isConnected = await _supabaseGmailService.isGmailConnected();
      setState(() {
        _isGmailConnected = isConnected;
      });

      if (isConnected) {
        final needsSync = await _supabaseGmailService.checkSyncNeeded();
        if (needsSync) {
          debugPrint('🔄 [PDA] Gmail sync needed on startup');
          _triggerQuickSync();
        }
      }
    } catch (e) {
      debugPrint('Error checking Gmail connection status: $e');
    }
  }

  Future<void> _checkLinkedInConnectionStatus() async {
    try {
      final isConnected = await _supabaseLinkedInService.isLinkedInConnected();
      setState(() {
        _isLinkedInConnected = isConnected;
      });
    } catch (e) {
      debugPrint('❌ [PDA] Error checking LinkedIn connection: $e');
    }
  }

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
    } catch (e) {
      debugPrint('❌ [PDA] Error checking Google Meet connection: $e');
    }
  }

  Future<void> _checkGoogleDriveConnectionStatus() async {
    try {
      final googleDriveRepo = _getIt<GoogleDriveRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      final isConnected = await googleDriveRepo.isGoogleDriveConnected(
        currentUser.uid,
      );
      setState(() {
        _isGoogleDriveConnected = isConnected;
      });
    } catch (e) {
      debugPrint('❌ [PDA] Error checking Google Drive connection: $e');
    }
  }

  // Gmail connection methods (keeping same logic)
  Future<void> _onConnectGmailPressed() async {
    if (_isGmailConnected) {
      _showGmailOptionsDialog();
      return;
    }

    setState(() {
      _isConnectingGmail = true;
      _error = null;
    });

    try {
      final result = await _supabaseGmailService.connectGmail();

      if (result.isSuccess) {
        setState(() {
          _isGmailConnected = true;
          _isConnectingGmail = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gmail connected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
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

  Future<void> _showInitialSyncDialog() async {
    await showGmailSyncDialog(
      context,
      onSyncSelected: (syncOptions) async {
        await _triggerGmailSyncWithOptions(syncOptions);
      },
    );
  }

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

  Future<void> _showSyncOptionsDialog() async {
    await showGmailSyncDialog(
      context,
      onSyncSelected: (syncOptions) async {
        await _triggerGmailSyncWithOptions(syncOptions);
      },
    );
  }

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

  // LinkedIn connection methods (keeping same logic)
  Future<void> _onConnectLinkedInPressed() async {
    if (_isLinkedInConnected) {
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

  Future<void> _triggerLinkedInSync() async {
    try {
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

  // Google Meet connection methods (keeping same logic)
  Future<void> _onConnectGoogleMeetPressed() async {
    if (_isGoogleMeetConnected) {
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

      await googleMeetDataSource.initiateGoogleMeetOAuth(currentUser.uid);

      setState(() {
        _isConnectingGoogleMeet = false;
        _error = 'Failed to get OAuth URL. Please try again.';
      });
    } catch (e) {
      if (e.toString().contains('OAuthUrlException:')) {
        final authUrl = e.toString().replaceFirst('OAuthUrlException: ', '');

        setState(() {
          _isConnectingGoogleMeet = false;
        });

        try {
          debugPrint('🌐 [GOOGLE MEET] Opening WebView for OAuth: $authUrl');

          final result = await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder: (context) => GoogleMeetOAuthWebView(
                oauthUrl: authUrl,
                redirectUri:
                    'https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync/callback',
                providerName: 'Google Meet',
              ),
            ),
          );

          if (result != null) {
            if (result['success'] == true) {
              final authCode = result['authCode'] as String?;
              if (authCode != null) {
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

  Future<void> _completeGoogleMeetOAuth(String authCode) async {
    try {
      setState(() {
        _isConnectingGoogleMeet = true;
      });

      final googleMeetRepo = _getIt<GoogleMeetRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final result = await googleMeetRepo.connectGoogleMeetAccount(
        userId: currentUser.uid,
        authCode: authCode,
      );

      if (result != null) {
        setState(() {
          _isGoogleMeetConnected = true;
          _isConnectingGoogleMeet = false;
        });

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

  void _navigateToGoogleMeetPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const GoogleMeetPage()));
  }

  // Google Drive connection methods (real OAuth via Supabase function)
  Future<void> _onConnectGoogleDrivePressed() async {
    if (_isGoogleDriveConnected) {
      _showGoogleDriveOptionsDialog();
      return;
    }

    setState(() {
      _isConnectingGoogleDrive = true;
      _error = null;
    });

    try {
      final driveDataSource = GoogleDriveSupabaseDataSourceImpl();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isConnectingGoogleDrive = false;
        });
        return;
      }

      await driveDataSource.initiateGoogleDriveOAuth(currentUser.uid);

      setState(() {
        _isConnectingGoogleDrive = false;
        _error = 'Failed to get OAuth URL. Please try again.';
      });
    } catch (e) {
      if (e.toString().contains('OAuthUrlException:')) {
        final authUrl = e.toString().replaceFirst('OAuthUrlException: ', '');

        setState(() {
          _isConnectingGoogleDrive = false;
        });

        try {
          debugPrint('🌐 [GOOGLE DRIVE] Opening WebView for OAuth: $authUrl');

          final result = await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder: (context) => GoogleMeetOAuthWebView(
                oauthUrl: authUrl,
                redirectUri:
                    'https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-drive-sync/callback',
                providerName: 'Google Drive',
              ),
            ),
          );

          if (result != null) {
            if (result['success'] == true) {
              final authCode = result['authCode'] as String?;
              if (authCode != null) {
                await _completeGoogleDriveOAuth(authCode);
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
          debugPrint('❌ [GOOGLE DRIVE] WebView error: $webViewError');
          setState(() {
            _error = 'Failed to open authentication page: $webViewError';
          });
        }
      } else {
        setState(() {
          _isConnectingGoogleDrive = false;
          _error = 'An error occurred while connecting Google Drive: $e';
        });
      }
    }
  }

  void _showGoogleDriveOptionsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Google Drive Connected'),
        content: const Text(
          'Your Google Drive is already connected. What would you like to do?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _triggerGoogleDriveSync();
            },
            child: const Text('Sync Now'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _disconnectGoogleDrive();
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

  Future<void> _triggerGoogleDriveSync() async {
    try {
      final googleDriveRepo = _getIt<GoogleDriveRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Syncing Google Drive...'),
          duration: Duration(seconds: 2),
        ),
      );

      await googleDriveRepo.triggerDriveSync(currentUser.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Google Drive sync completed.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error syncing Google Drive: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _disconnectGoogleDrive() async {
    try {
      final googleDriveRepo = _getIt<GoogleDriveRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await googleDriveRepo.disconnectGoogleDrive(currentUser.uid);

      setState(() {
        _isGoogleDriveConnected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Drive disconnected'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disconnecting Google Drive: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _completeGoogleDriveOAuth(String authCode) async {
    try {
      setState(() {
        _isConnectingGoogleDrive = true;
      });

      final googleDriveRepo = _getIt<GoogleDriveRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final success = await googleDriveRepo.connectGoogleDriveAccount(
        userId: currentUser.uid,
        authCode: authCode,
      );

      if (success) {
        setState(() {
          _isGoogleDriveConnected = true;
          _isConnectingGoogleDrive = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Google Drive connected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        try {
          await GoogleDriveContextPrewarmService().prewarmGoogleDriveContext();
        } catch (_) {}
      } else {
        setState(() {
          _isConnectingGoogleDrive = false;
          _error =
              'Failed to complete Google Drive connection. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnectingGoogleDrive = false;
        _error = 'Error completing OAuth: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      drawer: _buildSideDrawer(),
      body: Column(
        children: [
          _buildChatGptStyleAppBar(),
          if (_error != null) _buildErrorBanner(),
          Expanded(
            child: _isLoadingMessages && _messages.isEmpty
                ? PdaLoadingAnimation(
                    isLoading: _isLoadingMessages,
                    onAnimationComplete: () {},
                  )
                : _messages.isEmpty
                ? _buildWelcomeScreen()
                : _buildMessagesList(),
          ),
          if (_messages.isEmpty && !_isLoadingMessages) _buildSuggestionChips(),
          _buildChatGptStyleInputBar(),
        ],
      ),
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: sidebarBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: userBubbleColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Hushh PDA',
                    style: TextStyle(
                      color: sidebarTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: borderColor, height: 1),

            // Plugin Buttons Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Plugins',
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gmail Plugin - HIDDEN
                  // _buildPluginButton(
                  //   icon: Icons.mail_outline,
                  //   title: 'Gmail',
                  //   subtitle: _isGmailConnected ? 'Connected' : 'Connect',
                  //   isConnected: _isGmailConnected,
                  //   isLoading: _isConnectingGmail,
                  //   onTap: _onConnectGmailPressed,
                  // ),
                  // const SizedBox(height: 12),

                  // LinkedIn Plugin - HIDDEN
                  // _buildPluginButton(
                  //   icon: Icons.work_outline,
                  //   title: 'LinkedIn',
                  //   subtitle: _isLinkedInConnected ? 'Connected' : 'Connect',
                  //   isConnected: _isLinkedInConnected,
                  //   isLoading: _isConnectingLinkedIn,
                  //   onTap: _onConnectLinkedInPressed,
                  // ),
                  // const SizedBox(height: 12),

                  // Google Meet Plugin
                  _buildPluginButton(
                    icon: Icons.video_call_outlined,
                    title: 'Google Meet',
                    subtitle: _isGoogleMeetConnected
                        ? 'View meetings'
                        : 'Connect',
                    isConnected: _isGoogleMeetConnected,
                    isLoading: _isConnectingGoogleMeet,
                    onTap: _isGoogleMeetConnected
                        ? () => _navigateToGoogleMeetPage()
                        : _onConnectGoogleMeetPressed,
                  ),
                  const SizedBox(height: 12),

                  // Google Drive Plugin - HIDDEN
                  // _buildPluginButton(
                  //   icon: Icons.drive_folder_upload_outlined,
                  //   title: 'Google Drive',
                  //   subtitle: _isGoogleDriveConnected ? 'Connected' : 'Connect',
                  //   isConnected: _isGoogleDriveConnected,
                  //   isLoading: _isConnectingGoogleDrive,
                  //   onTap: _onConnectGoogleDrivePressed,
                  // ),
                  // const SizedBox(height: 12),

                  // Vault Plugin
                  _buildPluginButton(
                    icon: Icons.folder_open_rounded,
                    title: 'Vault',
                    subtitle: 'Access documents',
                    isConnected: true,
                    isLoading: false,
                    onTap: () => context.push(RoutePaths.vault),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _showClearConfirmation,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cleaning_services_outlined,
                            color: Colors.red[400],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Clear Chat',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConnected,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading
          ? null
          : () {
              debugPrint('🔥 Plugin button pressed: $title');
              onTap();
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: assistantBubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConnected ? userBubbleColor : borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isConnected ? userBubbleColor : hintColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: sidebarTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading ? 'Connecting...' : subtitle,
                    style: TextStyle(
                      color: isConnected ? userBubbleColor : hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(userBubbleColor),
                ),
              )
            else if (isConnected)
              Icon(Icons.check_circle, color: userBubbleColor, size: 20)
            else
              const Icon(Icons.arrow_forward_ios, color: hintColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChatGptStyleAppBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: lightBackground,
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Hamburger menu to open drawer
              Builder(
                builder: (context) => IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.menu, color: textColor, size: 24),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hushh PDA',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Clear chat button
              GestureDetector(
                onTap: _showClearConfirmation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cleaning_services_outlined,
                    color: Colors.red[400],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: userBubbleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.psychology_alt_outlined,
                size: 48,
                color: userBubbleColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How can I help you today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'I\'m your Hushh assistant. Ask me anything about the app, products, or connect your accounts for personalized help.',
              style: TextStyle(fontSize: 16, color: hintColor, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length + (_isSendingMessage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSendingMessage) {
          return _buildTypingIndicator();
        }
        final message = _messages[index];
        return _buildChatGptStyleMessageBubble(message);
      },
    );
  }

  Widget _buildChatGptStyleMessageBubble(PdaMessage message) {
    final isUser = message.isFromUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isUser ? userBubbleColor : assistantBubbleColor,
              borderRadius: BorderRadius.circular(16),
              border: isUser ? null : Border.all(color: borderColor),
            ),
            child: Icon(
              isUser ? Icons.person : Icons.psychology_alt_outlined,
              color: isUser ? Colors.white : textColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'Hushh PDA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.transparent : assistantBubbleColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isUser ? null : Border.all(color: borderColor),
                  ),
                  child: MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(fontSize: 15, color: textColor, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: assistantBubbleColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              Icons.psychology_alt_outlined,
              color: textColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hushh PDA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: assistantBubbleColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(hintColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Thinking...',
                        style: TextStyle(
                          fontSize: 15,
                          color: hintColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return InkWell(
            onTap: () => _sendMessage(predefinedMessage: suggestion['text']),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: assistantBubbleColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(suggestion['icon'], size: 16, color: hintColor),
                  const SizedBox(width: 8),
                  Text(
                    suggestion['text'],
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w500,
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

  Widget _buildChatGptStyleInputBar() {
    final isSendButtonEnabled =
        _messageController.text.trim().isNotEmpty && !_isSendingMessage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: lightBackground,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: assistantBubbleColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Message Hushh PDA...',
                    hintStyle: TextStyle(color: hintColor, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (text) {
                    if (isSendButtonEnabled) {
                      _sendMessage();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: isSendButtonEnabled ? userBubbleColor : hintColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: _isSendingMessage
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                onPressed: isSendButtonEnabled ? _sendMessage : null,
                padding: const EdgeInsets.all(8),
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
