import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hushh_user_app/features/pda/data/services/google_calendar_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:get_it/get_it.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hushh_user_app/features/pda/domain/entities/pda_message.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/send_message_use_case.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/get_messages_use_case.dart';
import 'package:hushh_user_app/features/pda/domain/usecases/clear_messages_use_case.dart';
import 'package:hushh_user_app/shared/constants/firestore_constants.dart';
import 'package:hushh_user_app/features/pda/presentation/components/pda_loading_animation.dart';

import '../../data/services/supabase_gmail_service.dart';
import '../../data/services/simple_linkedin_service.dart';
import '../widgets/gmail_sync_dialog.dart';
import '../widgets/sync_progress_dialog.dart';
import '../widgets/gmail_bottom_modal_sheet.dart';
import '../widgets/google_meet_bottom_modal_sheet.dart';
import '../../data/services/pda_preprocessing_manager.dart';
import '../widgets/preprocessing_status_widget.dart';
import '../../../../shared/services/gmail_sync_status_service.dart';
import '../../../../shared/widgets/gmail_sync_toast_overlay.dart';
import '../../../../shared/services/google_meet_sync_status_service.dart';
import '../../../../shared/widgets/google_meet_sync_toast_overlay.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hushh_user_app/shared/core/utils/toast_manager.dart';
import '../../data/services/gmail_context_prewarm_service.dart';
import '../../data/services/google_calendar_context_prewarm_service.dart';
import '../../data/data_sources/google_calendar_api_data_source.dart';
import '../../data/data_sources/google_calendar_supabase_data_source.dart';
import '../../data/data_sources/google_meet_supabase_data_source.dart';
import '../../data/services/google_calendar_cache_manager.dart';
import '../../data/services/google_meet_context_prewarm_service.dart';

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
  final PdaPreprocessingManager _preprocessingManager =
      PdaPreprocessingManager();
  final GmailSyncStatusService _gmailSyncStatusService =
      GmailSyncStatusService();
  final GoogleMeetSyncStatusService _googleMeetSyncStatusService =
      GoogleMeetSyncStatusService();

  List<PdaMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  bool _isPreprocessingRequired = false;
  bool _isPreprocessingComplete = false;
  PreprocessingStatus? _preprocessingStatus;
  bool _isGmailConnected = false;
  bool _isConnectingGmail = false;
  bool _isLinkedInConnected = false;
  bool _isConnectingLinkedIn = false;
  String? _currentUserName;
  bool _isGoogleMeetConnected = false;
  bool _isConnectingGoogleMeet = false;
  bool _isGoogleDriveConnected = false;
  bool _isConnectingGoogleDrive = false;
  String? _error;

  // Gmail sync status
  GmailSyncStatus? _gmailSyncStatus;
  StreamSubscription<GmailSyncStatus>? _gmailSyncStatusSubscription;
  bool _isGmailDataReady =
      true; // Default to true to allow messaging until checked

  // Google Meet sync status
  GoogleMeetSyncStatus? _googleMeetSyncStatus;
  StreamSubscription<GoogleMeetSyncStatus>? _googleMeetSyncStatusSubscription;
  bool _isGoogleMeetDataReady =
      true; // Default to true to allow messaging until checked

  // Periodic readiness check timer
  Timer? _googleMeetReadinessTimer;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];

  // Conversations
  String? _currentConversationId;
  String _currentConversationTitle = 'New chat';
  List<Map<String, dynamic>> _conversations = [];
  // Drawer search
  final TextEditingController _drawerSearchController = TextEditingController();
  String _drawerSearchQuery = '';
  String? _currentUserPhotoUrl;

  // Typing indicator variations
  final List<String> _typingMessages = [
    'Thinking...',
    'Processing...',
    'Analyzing...',
    'Preparing response...',
    'Working on it...',
    'Almost ready...',
  ];
  int _currentTypingIndex = 0;
  Timer? _typingTimer;

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
    _initializeConversations();
    _getCurrentUserName();
    _checkGmailConnectionStatus();
    _checkLinkedInConnectionStatus();
    _checkGoogleMeetConnectionStatus();
    _checkGoogleDriveConnectionStatus();
    _messageController.addListener(_updateSendButtonState);
    _drawerSearchController.addListener(() {
      setState(() {
        _drawerSearchQuery = _drawerSearchController.text.trim();
      });
    });

    // Initialize preprocessing
    _initializePreprocessing();

    // Initialize Gmail sync status tracking
    _initializeGmailSyncStatus();

    // Initialize Google Meet sync status tracking
    _initializeGoogleMeetSyncStatus();

    // Refresh username after a short delay to ensure Firebase is ready
    Future.delayed(const Duration(seconds: 1), () {
      _getCurrentUserName();
    });
  }

  /// Initialize Gmail sync status tracking
  Future<void> _initializeGmailSyncStatus() async {
    try {
      await _gmailSyncStatusService.initialize();

      // Listen to Gmail sync status changes
      _gmailSyncStatusSubscription = _gmailSyncStatusService.statusStream.listen((
        status,
      ) async {
        if (mounted) {
          setState(() {
            _gmailSyncStatus = status;
          });

          // Handle data readiness based on sync status
          if (status.isActive) {
            // If sync is active, data is definitely not ready
            setState(() {
              _isGmailDataReady = false;
            });
          } else if (status.isCompleted) {
            // If sync completed, assume data is ready and force update
            debugPrint(
              '🔄 [GMAIL STATUS] Sync completed, updating data readiness to true',
            );
            setState(() {
              _isGmailDataReady = true;
            });
            debugPrint(
              '✅ [GMAIL STATUS] Data ready set to true after sync completion',
            );
          }
          // If sync failed or other states, don't automatically change _isGmailDataReady
        }
      });

      // Check initial Gmail data readiness
      final isReady = await _gmailSyncStatusService
          .isGmailDataReadyInLocalStorage();
      if (mounted) {
        setState(() {
          _isGmailDataReady = isReady;
        });
      }

      debugPrint('🔄 [GMAIL SYNC STATUS] Initialized - Data ready: $isReady');
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC STATUS] Error initializing: $e');
      // Default to allowing messaging if initialization fails
      if (mounted) {
        setState(() {
          _isGmailDataReady = true;
        });
      }
    }
  }

  /// Initialize Google Meet sync status tracking
  Future<void> _initializeGoogleMeetSyncStatus() async {
    try {
      await _googleMeetSyncStatusService.initialize();

      // Listen to Google Meet sync status changes
      _googleMeetSyncStatusSubscription = _googleMeetSyncStatusService.statusStream.listen((
        status,
      ) async {
        if (mounted) {
          setState(() {
            _googleMeetSyncStatus = status;
          });

          // Handle data readiness based on sync status
          if (status.isActive) {
            // If sync is active, data is definitely not ready
            setState(() {
              _isGoogleMeetDataReady = false;
            });
          } else if (status.isCompleted) {
            // If sync completed, verify data is actually ready through proper check
            debugPrint(
              '🔄 [GOOGLE MEET STATUS] Sync completed, verifying data readiness...',
            );

            // Check if data is actually ready for queries
            await _refreshGoogleMeetDataReadiness();

            // Add periodic checks for calendar data readiness if still not ready
            if (!_isGoogleMeetDataReady) {
              _startPeriodicGoogleMeetReadinessCheck();
            }
          }
          // If sync failed or other states, don't automatically change _isGoogleMeetDataReady
        }
      });

      // Check initial Google Meet data readiness
      final isReady = await _googleMeetSyncStatusService
          .isGoogleMeetDataReadyInLocalStorage();
      if (mounted) {
        setState(() {
          _isGoogleMeetDataReady = isReady;
        });
      }

      debugPrint(
        '🔄 [GOOGLE MEET SYNC STATUS] Initialized - Data ready: $isReady',
      );
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET SYNC STATUS] Error initializing: $e');
      // Default to allowing messaging if initialization fails
      if (mounted) {
        setState(() {
          _isGoogleMeetDataReady = true;
        });
      }
    }
  }

  /// Initialize preprocessing system
  Future<void> _initializePreprocessing() async {
    try {
      // Check if preprocessing is already completed
      if (_preprocessingManager.isCompleted) {
        debugPrint('✅ [PDA] Preprocessing already completed');
        if (mounted) {
          setState(() {
            _isPreprocessingRequired = false;
            _isPreprocessingComplete = true;
          });
        }
        return;
      }

      // Check if preprocessing is currently in progress
      if (_preprocessingManager.isPreprocessing) {
        debugPrint(
          '🔄 [PDA] Preprocessing already in progress, showing status',
        );
        if (mounted) {
          setState(() {
            _isPreprocessingRequired = true;
            _isPreprocessingComplete = false;
          });
        }

        // Listen to preprocessing status
        _preprocessingManager.statusStream.listen((status) {
          if (mounted) {
            setState(() {
              _preprocessingStatus = status;
              _isPreprocessingComplete = status.isCompleted;
            });
          }
        });
        return;
      }

      // Check if preprocessing is required
      final isRequired = await _preprocessingManager.isPreprocessingRequired();

      if (mounted) {
        setState(() {
          _isPreprocessingRequired = isRequired;
          _isPreprocessingComplete =
              !isRequired; // If not required, mark as complete
        });
      }

      if (isRequired) {
        debugPrint('🚀 [PDA] Preprocessing required, starting...');

        // Listen to preprocessing status
        _preprocessingManager.statusStream.listen((status) {
          if (mounted) {
            setState(() {
              _preprocessingStatus = status;
              _isPreprocessingComplete = status.isCompleted;
            });
          }
        });

        // Start preprocessing (this will now check if already completed/in progress)
        await _preprocessingManager.startPreprocessing();
      } else {
        debugPrint('ℹ️ [PDA] No preprocessing required');
      }
    } catch (e) {
      debugPrint('❌ [PDA] Error initializing preprocessing: $e');
      // If there's an error, allow messaging anyway
      if (mounted) {
        setState(() {
          _isPreprocessingComplete = true;
        });
      }
    }
  }

  Future<void> _initializeConversations() async {
    await _loadConversations();
    // If we have conversations, load last used; otherwise do not auto-create
    if (_currentConversationId != null) {
      await _loadMessages();
    } else if (_conversations.isEmpty) {
      // Create first only if there are none
      await _createNewConversation();
    }
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

  Future<void> _getCurrentUserName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('🔍 [PDA USERNAME] Current user: ${currentUser?.uid}');

    if (currentUser != null) {
      try {
        debugPrint('🔍 [PDA USERNAME] Fetching from HushUsers collection...');
        // Fetch user data from HushUsers collection
        final userDoc = await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(currentUser.uid)
            .get();

        debugPrint('🔍 [PDA USERNAME] Document exists: ${userDoc.exists}');
        debugPrint('🔍 [PDA USERNAME] Document data: ${userDoc.data()}');

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;

          // Try different field names for the full name
          final fullName =
              userData['fullname'] as String? ??
              userData['fullName'] as String? ??
              userData['name'] as String? ??
              userData['displayName'] as String? ??
              userData['firstName'] as String?;

          debugPrint('🔍 [PDA USERNAME] Full name from Firestore: $fullName');
          debugPrint(
            '🔍 [PDA USERNAME] Available fields: ${userData.keys.toList()}',
          );

          if (mounted) {
            setState(() {
              _currentUserName = fullName?.isNotEmpty == true
                  ? fullName
                  : currentUser.displayName ??
                        currentUser.email?.split('@').first ??
                        'User';
              _currentUserPhotoUrl = currentUser.photoURL;
            });
          }

          debugPrint(
            '🔍 [PDA USERNAME] Final username set to: $_currentUserName',
          );
        } else {
          debugPrint(
            '🔍 [PDA USERNAME] Document does not exist, using fallback',
          );
          // Fallback to Firebase Auth data if HushUsers document doesn't exist
          if (mounted) {
            setState(() {
              _currentUserName =
                  currentUser.displayName ??
                  currentUser.email?.split('@').first ??
                  'User';
              _currentUserPhotoUrl = currentUser.photoURL;
            });
          }
          debugPrint(
            '🔍 [PDA USERNAME] Fallback username set to: $_currentUserName',
          );
        }
      } catch (e) {
        debugPrint('❌ [PDA USERNAME] Error fetching username: $e');
        // Fallback to Firebase Auth data on error
        if (mounted) {
          setState(() {
            _currentUserName =
                currentUser.displayName ??
                currentUser.email?.split('@').first ??
                'User';
          });
        }
        debugPrint(
          '🔍 [PDA USERNAME] Error fallback username set to: $_currentUserName',
        );
      }
    } else {
      debugPrint('🔍 [PDA USERNAME] No current user found');
    }
  }

  void _startTypingAnimation() {
    _typingTimer?.cancel();
    _currentTypingIndex = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentTypingIndex =
              (_currentTypingIndex + 1) % _typingMessages.length;
        });
      }
    });
  }

  void _stopTypingAnimation() {
    _typingTimer?.cancel();
    _typingTimer = null;
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  Future<void> _ensureConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (_currentConversationId != null) return;

    final docRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(currentUser.uid)
        .collection('pda_conversations')
        .doc();
    await docRef.set({
      'title': _currentConversationTitle,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    setState(() {
      _currentConversationId = docRef.id;
    });
  }

  Future<void> _loadConversations() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final qs = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(currentUser.uid)
        .collection('pda_conversations')
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .get();
    final list = qs.docs.map((d) => {'id': d.id, ...(d.data())}).toList();
    // Restore last active conversation from prefs
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString('pda_last_conversation_id');
    setState(() {
      _conversations = list;
      if (lastId != null && list.any((c) => c['id'] == lastId)) {
        _currentConversationId = lastId;
        _currentConversationTitle =
            (list.firstWhere((c) => c['id'] == lastId)['title'] as String?) ??
            'Conversation';
      } else if (list.isNotEmpty && _currentConversationId == null) {
        _currentConversationId = list.first['id'] as String;
        _currentConversationTitle =
            (list.first['title'] as String?) ?? 'Conversation';
      }
    });
  }

  Future<void> _createNewConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Close the drawer first if we can pop
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Delete any empty conversations before creating a new one
    await _deleteEmptyConversations();

    final docRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(currentUser.uid)
        .collection('pda_conversations')
        .doc();
    await docRef.set({
      'title': 'New chat',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    setState(() {
      _currentConversationId = docRef.id;
      _currentConversationTitle = 'New chat';
      _messages.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pda_last_conversation_id', docRef.id);
    await _loadConversations();
  }

  Future<void> _openConversation(Map<String, dynamic> convo) async {
    // Close the drawer first if we can pop
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    setState(() {
      _currentConversationId = convo['id'] as String;
      _currentConversationTitle = (convo['title'] as String?) ?? 'Conversation';
      _messages.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pda_last_conversation_id', _currentConversationId!);
    await _loadMessages();
  }

  Future<List<String>> _uploadSelectedImages(List<File> images) async {
    if (images.isEmpty) return [];
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];
    final storage = FirebaseStorage.instance;
    final List<String> urls = [];
    for (final file in images) {
      final fileName = file.path.split('/').last;
      final ref = storage.ref().child(
        'pda/${currentUser.uid}/${_currentConversationId ?? 'default'}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _deleteConversation(
    String conversationId, {
    bool showSnackbar = true,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final convoRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(currentUser.uid)
        .collection('pda_conversations')
        .doc(conversationId);

    try {
      // Delete all messages in subcollection (chunked batches of 400)
      const int chunkSize = 400;
      while (true) {
        final msgChunk = await convoRef
            .collection('messages')
            .limit(chunkSize)
            .get();
        if (msgChunk.docs.isEmpty) break;
        final batch = FirebaseFirestore.instance.batch();
        for (final d in msgChunk.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }

      // Finally delete the conversation doc
      await convoRef.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_currentConversationId == conversationId) {
      setState(() {
        _currentConversationId = null;
        _messages.clear();
        _currentConversationTitle = 'New chat';
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pda_last_conversation_id');
      await _loadConversations();
      if (_conversations.isEmpty) {
        await _createNewConversation();
      }
      await _loadMessages();
    }
    await _loadConversations();
    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat deleted'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Delete all empty conversations (conversations with no messages)
  Future<void> _deleteEmptyConversations() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Get all conversations
      final conversationsSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(currentUser.uid)
          .collection('pda_conversations')
          .get();

      final emptyConversationIds = <String>[];

      // Check each conversation for messages
      for (final conversationDoc in conversationsSnapshot.docs) {
        final messagesSnapshot = await conversationDoc.reference
            .collection('messages')
            .limit(1) // We only need to check if any messages exist
            .get();

        // If no messages exist, mark for deletion
        if (messagesSnapshot.docs.isEmpty) {
          emptyConversationIds.add(conversationDoc.id);
        }
      }

      // Delete all empty conversations (silently, no snackbar)
      for (final conversationId in emptyConversationIds) {
        await _deleteConversation(conversationId, showSnackbar: false);
      }

      if (emptyConversationIds.isNotEmpty) {
        debugPrint(
          '🗑️ [PDA] Deleted ${emptyConversationIds.length} empty conversations',
        );
      }
    } catch (e) {
      debugPrint('❌ [PDA] Error deleting empty conversations: $e');
    }
  }

  void _confirmDeleteConversation(String conversationId) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete chat?'),
        content: const Text('This will permanently delete this conversation.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteConversation(conversationId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(String metadata) {
    final imagePaths = metadata.split('|');

    if (imagePaths.length == 1) {
      // Single image - display as square
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imagePaths[0].startsWith('http')
            ? Image.network(
                imagePaths[0],
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              )
            : Image.file(
                File(imagePaths[0]),
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
      );
    } else {
      // Multiple images - display in a grid
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: imagePaths.map((path) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: path.startsWith('http')
                ? Image.network(
                    path,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          );
        }).toList(),
      );
    }
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
      if (_currentConversationId != null) {
        final qs = await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(currentUser.uid)
            .collection('pda_conversations')
            .doc(_currentConversationId)
            .collection('messages')
            .orderBy('timestamp')
            .get();

        final list = qs.docs.map((d) {
          final data = d.data();
          final type = (data['message_type'] as String?) ?? 'text';
          return PdaMessage(
            id: d.id,
            hushhId: data['hushh_id'] ?? currentUser.uid,
            content: data['content'] ?? '',
            isFromUser: data['is_from_user'] ?? false,
            timestamp:
                DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
            messageType: type == 'image' ? MessageType.image : MessageType.text,
            metadata: data['metadata'] as String?,
            cost: (data['cost'] is num)
                ? (data['cost'] as num).toDouble()
                : null,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _messages = list;
            _isLoadingMessages = false;
          });
          _scrollToBottom();
        }
      } else {
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
                _messages = messages.reversed.toList();
                _isLoadingMessages = false;
              });
              _scrollToBottom();
            }
          },
        );
      }
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
    if (message.isEmpty && _selectedImages.isEmpty) return;

    // If either plugin is disconnected, avoid using their context
    if (!_isGmailConnected || !_isGoogleMeetConnected) {
      // Silently proceed; context-level checks already prevent usage
    }

    // Block sending messages if preprocessing is not complete
    if (_isPreprocessingRequired && !_isPreprocessingComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⏳ Please wait for data preprocessing to complete before sending messages',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Block sending messages if Gmail sync is active
    if (!_isGmailDataReady && _gmailSyncStatus?.isActive == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '📧 Gmail is syncing your emails. Please wait for sync to complete before sending messages.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Block sending messages if Google Meet sync is active
    if (!_isGoogleMeetDataReady && _googleMeetSyncStatus?.isActive == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '📅 Google Meet is syncing your calendar events. Please wait for sync to complete before sending messages.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

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
          content: message.isEmpty
              ? '[${_selectedImages.length} Image${_selectedImages.length > 1 ? 's' : ''}]'
              : message,
          isFromUser: true,
          timestamp: DateTime.now(),
          messageType: _selectedImages.isNotEmpty
              ? MessageType.image
              : MessageType.text,
          metadata: _selectedImages.isNotEmpty
              ? _selectedImages.map((f) => f.path).join('|')
              : null,
        ),
      );
      _messageController.clear();
      _isSendingMessage = true;
      _error = null;
    });
    _scrollToBottom();
    _startTypingAnimation();

    // Store images before clearing them
    final imagesToSend = List<File>.from(_selectedImages);

    try {
      debugPrint(
        '🔍 [PDA UI] Sending message with ${imagesToSend.length} images',
      );
      if (imagesToSend.isNotEmpty) {
        for (int i = 0; i < imagesToSend.length; i++) {
          debugPrint('🔍 [PDA UI] Image ${i + 1}: ${imagesToSend[i].path}');
        }
      }

      // Upload images (if any) to Firebase Storage to get URLs
      final imageUrls = await _uploadSelectedImages(imagesToSend);

      final sendMessageUseCase = _getIt<PdaSendMessageUseCase>();
      final result = await sendMessageUseCase(
        hushhId: currentUser.uid,
        message: message,
        context: _messages,
        imageFiles: imagesToSend.isNotEmpty ? imagesToSend : null,
        imageUrls: imageUrls,
      );

      result.fold(
        (failure) {
          _stopTypingAnimation();
          setState(() {
            _error = 'Failed to send: ${failure.toString()}';
            _isSendingMessage = false;
          });
        },
        (aiMessage) async {
          _stopTypingAnimation();
          setState(() {
            _messages.add(aiMessage);
            _isSendingMessage = false;
            _selectedImages.clear(); // Clear images after successful send
          });
          // Persist the last user and AI messages into conversation history
          try {
            final currentUser = FirebaseAuth.instance.currentUser;
            final convId = _currentConversationId;
            if (currentUser != null &&
                convId != null &&
                _messages.length >= 2) {
              final convoRef = FirebaseFirestore.instance
                  .collection(FirestoreCollections.users)
                  .doc(currentUser.uid)
                  .collection('pda_conversations')
                  .doc(convId);
              final msgsRef = convoRef.collection('messages');

              final userMsg = _messages[_messages.length - 2];
              await msgsRef.doc(userMsg.id).set({
                'hushh_id': userMsg.hushhId,
                'content': userMsg.content,
                'is_from_user': true,
                'timestamp': userMsg.timestamp.toIso8601String(),
                'message_type': userMsg.messageType.name,
                'metadata': imageUrls.isNotEmpty
                    ? imageUrls.join('|')
                    : userMsg.metadata,
              });

              await msgsRef.doc(aiMessage.id).set({
                'hushh_id': aiMessage.hushhId,
                'content': aiMessage.content,
                'is_from_user': false,
                'timestamp': aiMessage.timestamp.toIso8601String(),
                'message_type': aiMessage.messageType.name,
                'metadata': aiMessage.metadata,
                'cost': aiMessage.cost,
              });

              await convoRef.update({
                'updatedAt': DateTime.now().toIso8601String(),
                if (_currentConversationTitle == 'New chat' &&
                    message.isNotEmpty)
                  'title': message.length > 40
                      ? message.substring(0, 40)
                      : message,
              });

              await _loadConversations();
            }
          } catch (e) {
            debugPrint('❌ [PDA] Failed to persist conversation: $e');
          }
          _scrollToBottom();
        },
      );
    } catch (e) {
      _stopTypingAnimation();
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
      if (mounted) {
        setState(() {
          _isLinkedInConnected = isConnected;
        });
      }
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

      // SIMPLE LOGIC: If connected, data is ready. Period.
      // If we have a Google Meet account, sync must have completed at some point
      final isDataReady = isConnected; // If connected → data ready

      if (mounted) {
        setState(() {
          _isGoogleMeetConnected = isConnected;
          _isGoogleMeetDataReady = isDataReady;
        });
      }

      debugPrint(
        '🚀 [GOOGLE MEET INIT] IMMEDIATE STATUS - Connected: $isConnected, Ready: $isDataReady',
      );
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
      if (mounted) {
        setState(() {
          _isGoogleDriveConnected = isConnected;
        });
      }
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
          _isGmailDataReady = false; // Data not ready until sync completes
        });

        if (mounted) {
          // No interim snackbar; open sync options directly
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
      onSyncSelected: _triggerGmailSyncWithOptions,
    );
  }

  void _showGmailOptionsDialog() {
    // Close the drawer first if we can pop
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showGmailBottomModalSheet(
      context,
      isConnected: _isGmailConnected,
      onConnect: _onConnectGmailPressed,
      onSyncSelected: _triggerGmailSyncWithOptions,
      onQuickSync: _triggerQuickSync,
      onDisconnect: _disconnectGmail,
    );
  }

  Future<void> _showSyncOptionsDialog() async {
    await showGmailSyncDialog(
      context,
      onSyncSelected: _triggerGmailSyncWithOptions,
    );
  }

  Future<void> _triggerGmailSyncWithOptions(SyncOptions syncOptions) async {
    // Start background sync (no snackbars)
    _performBackgroundGmailSync(syncOptions);
  }

  Future<void> _performBackgroundGmailSync(SyncOptions syncOptions) async {
    try {
      debugPrint('🔄 [GMAIL SYNC] Starting background sync...');
      final result = await _supabaseGmailService.syncEmails(syncOptions);

      if (mounted) {
        if (result.isSuccess) {
          // Final success snackbar (to match existing Gmail UX)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gmail sync completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Re-check Gmail data readiness after sync completion
          await _refreshGmailDataReadiness();

          // Trigger PDA prewarming after successful sync with delay
          debugPrint('🚀 [PDA] Triggering prewarming after Gmail sync...');
          try {
            await Future.delayed(const Duration(seconds: 3));
            _preprocessingManager.reset();
            await _preprocessingManager.startPreprocessing();
            debugPrint('✅ [PDA] Prewarming completed after Gmail sync');
            if (mounted) {
              setState(() {
                _isPreprocessingComplete = true;
              });
            }
          } catch (e) {
            debugPrint('❌ [PDA] Prewarming failed after Gmail sync: $e');
            try {
              await _preprocessingManager.startPreprocessing();
            } catch (fallbackError) {
              debugPrint(
                '❌ [PDA] Fallback preprocessing also failed: $fallbackError',
              );
            }
          }
        } else {
          debugPrint('⚠️ Gmail sync failed: ${result.error}');
        }
      }
    } catch (e) {
      debugPrint('❌ [GMAIL SYNC] Background sync error: $e');
    }
  }

  /// Refresh Gmail data readiness status after sync completion
  Future<void> _refreshGmailDataReadiness() async {
    try {
      debugPrint('🔄 [GMAIL STATUS] Refreshing Gmail data readiness...');

      // Try multiple times with increasing delays to handle Firestore eventual consistency
      for (int attempt = 1; attempt <= 5; attempt++) {
        await Future.delayed(Duration(seconds: attempt * 2));

        final isReady = await _gmailSyncStatusService
            .isGmailDataReadyInLocalStorage();

        debugPrint(
          '🔄 [GMAIL STATUS] Attempt $attempt: Gmail data ready = $isReady',
        );

        if (isReady) {
          if (mounted) {
            setState(() {
              _isGmailDataReady = true;
            });
            debugPrint('✅ [GMAIL STATUS] Gmail data ready updated: true');
          }
          return; // Exit early if data is ready
        }
      }

      // If still not ready after 5 attempts, force it to true
      debugPrint(
        '⚠️ [GMAIL STATUS] Forcing Gmail data ready to true after 5 attempts',
      );
      if (mounted) {
        setState(() {
          _isGmailDataReady = true;
        });
      }
    } catch (e) {
      debugPrint('❌ [GMAIL STATUS] Error refreshing data readiness: $e');
      // Default to ready if there's an error
      if (mounted) {
        setState(() {
          _isGmailDataReady = true;
        });
      }
    }
  }

  /// Refresh Google Meet data readiness status after sync completion
  Future<void> _refreshGoogleMeetDataReadiness() async {
    try {
      debugPrint(
        '🔄 [GOOGLE MEET STATUS] Refreshing Google Meet data readiness...',
      );

      // Try multiple times with increasing delays to handle Firestore eventual consistency
      for (int attempt = 1; attempt <= 5; attempt++) {
        await Future.delayed(Duration(seconds: attempt * 2));

        final isReady = await _googleMeetSyncStatusService
            .isGoogleMeetDataReadyInLocalStorage();

        debugPrint(
          '🔄 [GOOGLE MEET STATUS] Attempt $attempt: Google Meet data ready = $isReady',
        );

        if (isReady) {
          if (mounted) {
            setState(() {
              _isGoogleMeetDataReady = true;
            });
            debugPrint(
              '✅ [GOOGLE MEET STATUS] Google Meet data ready updated: true',
            );
          }
          return; // Exit early if data is ready
        }
      }

      // If still not ready after 5 attempts, force it to true
      debugPrint(
        '⚠️ [GOOGLE MEET STATUS] Forcing Google Meet data ready to true after 5 attempts',
      );
      if (mounted) {
        setState(() {
          _isGoogleMeetDataReady = true;
        });
      }
    } catch (e) {
      debugPrint('❌ [GOOGLE MEET STATUS] Error refreshing data readiness: $e');
      // Default to ready if there's an error
      if (mounted) {
        setState(() {
          _isGoogleMeetDataReady = true;
        });
      }
    }
  }

  /// Start periodic checking for Google Meet calendar data readiness
  void _startPeriodicGoogleMeetReadinessCheck() {
    _googleMeetReadinessTimer?.cancel();

    debugPrint('⏰ [GOOGLE MEET STATUS] Starting periodic readiness check...');

    _googleMeetReadinessTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final isReady = await _googleMeetSyncStatusService
            .isGoogleMeetDataReadyInLocalStorage();

        debugPrint(
          '⏰ [GOOGLE MEET STATUS] Periodic check: data ready = $isReady',
        );

        if (isReady) {
          if (mounted) {
            setState(() {
              _isGoogleMeetDataReady = true;
            });
            debugPrint(
              '✅ [GOOGLE MEET STATUS] Periodic check found data ready - stopping timer',
            );
          }
          timer.cancel();
        }
      } catch (e) {
        debugPrint('❌ [GOOGLE MEET STATUS] Error in periodic check: $e');
      }
    });
  }

  Future<void> _triggerQuickSync() async {
    try {
      final result = await _supabaseGmailService.syncGmailNow();

      if (result.isSuccess) {
        // Final success toast only
        ToastManager.showToast(context, 'Gmail quick sync completed');
      } else {
        // No snackbars during connect/sync; just log
        debugPrint('⚠️ Quick sync failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ Error during quick sync: $e');
    }
  }

  Future<void> _disconnectGmail() async {
    try {
      final result = await _supabaseGmailService.disconnectGmail();

      if (result.isSuccess) {
        setState(() {
          _isGmailConnected = false;
          _isGmailDataReady = false;
        });

        // Clear Gmail PDA context cache
        final gmailPrewarm = GmailContextPrewarmService();
        await gmailPrewarm.clearGmailContextCache();

        // Toast instead of snackbar
        ToastManager.showToast(context, 'Gmail disconnected');
      } else {
        // Avoid noisy snackbars; log instead
        debugPrint('Failed to disconnect Gmail: ${result.error}');
      }
    } catch (e) {
      // Avoid noisy snackbars; log instead
      debugPrint('Error disconnecting Gmail: $e');
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
    // Show sync progress dialog with PDA animation
    showSyncProgressDialog(
      context,
      title: 'Syncing LinkedIn',
      description: 'Fetching profile and posts data',
      onCompleted: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ LinkedIn data synced successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );

    try {
      const syncOptions = LinkedInSyncOptions(
        includeProfile: true,
        includePosts: true,
      );

      final result = await _supabaseLinkedInService.syncLinkedInData(
        syncOptions,
      );

      if (!result && mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync LinkedIn data. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing LinkedIn data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
        // IMMEDIATE UPDATE: Data is ready locally, update UI immediately
        setState(() {
          _isGoogleMeetConnected = true;
          _isGoogleMeetDataReady =
              true; // Data is ready immediately after OAuth + sync
          _isConnectingGoogleMeet = false;
        });

        debugPrint(
          '🚀 [PDA UI] Google Meet OAuth completed - UI updated immediately with ready state',
        );

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
    // Close the drawer first if we can pop
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showGoogleMeetBottomModalSheet(
      context,
      isConnected: _isGoogleMeetConnected,
      onConnect: _onConnectGoogleMeetPressed,
      onSync: _triggerGoogleMeetSync,
      onDisconnect: _disconnectGoogleMeet,
    );
  }

  Future<void> _triggerGoogleMeetSync() async {
    try {
      final googleMeetRepo = _getIt<GoogleMeetRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Start Meet sync (progress will be shown by GoogleMeetSyncToastOverlay)
      await googleMeetRepo.syncGoogleMeetData(currentUser.uid);

      if (mounted) {
        // Final success snackbar to mirror Gmail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Google Meet data synced successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error syncing Google Meet data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
        _isGoogleMeetDataReady = false;
      });

      // Clear Google Meet context caches (memory, SharedPreferences, Firestore)
      try {
        final meetPrewarm = _getIt<GoogleMeetContextPrewarmService>();
        await meetPrewarm.clearGoogleMeetContextCache();
      } catch (e) {
        debugPrint(
          '⚠️ [PDA] Could not clear Google Meet context on disconnect: $e',
        );
      }

      // Clear Calendar context caches related to meetings
      try {
        final calendarPrewarm = _getIt<GoogleCalendarContextPrewarmService>();
        await calendarPrewarm.clearPDAContextCachePublic(currentUser.uid);

        final calendarCache = _getIt<GoogleCalendarCacheManager>();
        await calendarCache.clearUserCache(currentUser.uid);
      } catch (e) {
        debugPrint(
          '⚠️ [PDA] Could not clear calendar caches on disconnect: $e',
        );
      }

      ToastManager.showToast(context, 'Google Meet disconnected');
    } catch (e) {
      debugPrint('Error disconnecting Google Meet: $e');
      ToastManager.showToast(
        context,
        'Error disconnecting Google Meet',
        type: ToastType.error,
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
    // Show sync progress dialog with PDA animation
    showSyncProgressDialog(
      context,
      title: 'Syncing Google Drive',
      description: 'Fetching files and documents',
      onCompleted: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Google Drive sync completed.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );

    try {
      final googleDriveRepo = _getIt<GoogleDriveRepository>();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await googleDriveRepo.triggerDriveSync(currentUser.uid);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error syncing Google Drive: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

  /// Get Gmail subtitle based on connection and sync status
  String _getGmailSubtitle() {
    if (!_isGmailConnected) {
      return 'Connect';
    }

    if (_gmailSyncStatus?.isActive == true) {
      return 'Syncing emails...';
    }

    if (!_isGmailDataReady) {
      return 'Data loading...';
    }

    return 'View emails';
  }

  /// Get Google Meet subtitle based on connection and sync status
  String _getGoogleMeetSubtitle() {
    if (!_isGoogleMeetConnected) {
      return 'Connect';
    }

    if (_googleMeetSyncStatus?.isActive == true) {
      return 'Syncing calendar...';
    }

    if (!_isGoogleMeetDataReady) {
      return 'Data loading...';
    }

    return 'View meetings';
  }

  /// Handle Gmail plugin tap with sync status checking
  Future<void> _onGmailPluginTapped() async {
    if (!_isGmailConnected) {
      await _onConnectGmailPressed();
      return;
    }

    // Check if sync is active
    if (_gmailSyncStatus?.isActive == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '📧 Gmail is syncing your emails. Please wait for sync to complete before accessing Gmail page.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Check if data is ready in local storage
    if (!_isGmailDataReady) {
      final isReady = await _gmailSyncStatusService
          .isGmailDataReadyInLocalStorage();

      if (!isReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📧 Gmail data is still being processed',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please wait for the sync process to complete before accessing your emails.',
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      } else {
        // Update state if data is now ready
        setState(() {
          _isGmailDataReady = true;
        });
      }
    }

    // All checks passed, navigate to Gmail page
    context.push(RoutePaths.gmail);
  }

  /// Get appropriate hint text based on current sync status
  String _getSyncingHintText() {
    if (_isPreprocessingRequired && !_isPreprocessingComplete) {
      return 'Processing data, please wait...';
    }

    if (_isConnectingGmail ||
        (_gmailSyncStatus?.isActive == true && !_isGmailDataReady)) {
      return 'Gmail is syncing, please wait...';
    }

    if (_isConnectingGoogleMeet ||
        (_googleMeetSyncStatus?.isActive == true && !_isGoogleMeetDataReady) ||
        (!_isGoogleMeetDataReady && _isGoogleMeetConnected)) {
      return 'Meet is syncing, please wait...';
    }

    return 'Please wait for response...';
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
    return GmailSyncToastOverlay(
      child: GoogleMeetSyncToastOverlay(
        child: Scaffold(
          backgroundColor: lightBackground,
          drawer: _buildSideDrawer(),
          body: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                _buildChatGptStyleAppBar(),
                if (_error != null) _buildErrorBanner(),
                Expanded(
                  child: _isLoadingMessages && _messages.isEmpty
                      ? PdaLoadingAnimation(
                          isLoading: _isLoadingMessages,
                          onAnimationComplete: () {},
                        )
                      : (_isPreprocessingRequired && !_isPreprocessingComplete)
                      ? PdaLoadingAnimation(
                          isLoading: true,
                          showPreprocessingStatus: true,
                          onAnimationComplete: () {
                            setState(() {
                              _isPreprocessingComplete = true;
                            });
                          },
                        )
                      : _messages.isEmpty
                      ? _buildWelcomeScreen()
                      : _buildMessagesList(),
                ),
                if (_messages.isEmpty &&
                    !_isLoadingMessages &&
                    _isPreprocessingComplete)
                  _buildSuggestionChips(),
                _buildChatGptStyleInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: sidebarBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: const [
                  Icon(Icons.psychology_alt_outlined, color: sidebarTextColor),
                  SizedBox(width: 8),
                  Text(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _drawerSearchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search',
                  isDense: true,
                  filled: true,
                  fillColor: assistantBubbleColor,
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: hintColor,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 24,
                  ),
                  suffixIcon: _drawerSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: hintColor,
                          ),
                          onPressed: () => _drawerSearchController.clear(),
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: borderColor, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _createNewConversation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: assistantBubbleColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add, color: sidebarTextColor),
                            SizedBox(width: 8),
                            Text(
                              'New chat',
                              style: TextStyle(color: sidebarTextColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text(
                      'Plugins',
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Gmail
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(
                      Icons.mail_outline,
                      color: sidebarTextColor,
                    ),
                    title: const Text(
                      'Gmail',
                      style: TextStyle(color: sidebarTextColor),
                    ),
                    subtitle: Text(
                      (_isConnectingGmail ||
                              (_isGmailConnected && !_isGmailDataReady))
                          ? 'Connecting...'
                          : _getGmailSubtitle(),
                      style: const TextStyle(color: hintColor, fontSize: 12),
                    ),
                    trailing:
                        (_isConnectingGmail ||
                            (_isGmailConnected && !_isGmailDataReady))
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                userBubbleColor,
                              ),
                            ),
                          )
                        : (_isGmailConnected && _isGmailDataReady)
                        ? const Icon(
                            Icons.check_circle,
                            color: userBubbleColor,
                            size: 18,
                          )
                        : null,
                    onTap:
                        (_isConnectingGmail ||
                            (_isGmailConnected && !_isGmailDataReady))
                        ? null
                        : () => _onGmailPluginTapped(),
                    onLongPress:
                        (_isConnectingGmail ||
                            (_isGmailConnected && !_isGmailDataReady))
                        ? null
                        : () {
                            if (_isGmailConnected) {
                              _showGmailOptionsDialog();
                            } else {
                              _onConnectGmailPressed();
                            }
                          },
                  ),
                  // Google Meet
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(
                      Icons.video_call_outlined,
                      color: sidebarTextColor,
                    ),
                    title: const Text(
                      'Google Meet',
                      style: TextStyle(color: sidebarTextColor),
                    ),
                    subtitle: Text(
                      (_isConnectingGoogleMeet ||
                              (_isGoogleMeetConnected &&
                                  !_isGoogleMeetDataReady))
                          ? 'Connecting...'
                          : _getGoogleMeetSubtitle(),
                      style: const TextStyle(color: hintColor, fontSize: 12),
                    ),
                    trailing:
                        (_isConnectingGoogleMeet ||
                            (_isGoogleMeetConnected && !_isGoogleMeetDataReady))
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                userBubbleColor,
                              ),
                            ),
                          )
                        : (_isGoogleMeetConnected && _isGoogleMeetDataReady)
                        ? const Icon(
                            Icons.check_circle,
                            color: userBubbleColor,
                            size: 18,
                          )
                        : null,
                    onTap:
                        (_isConnectingGoogleMeet ||
                            (_isGoogleMeetConnected && !_isGoogleMeetDataReady))
                        ? null
                        : (_isGoogleMeetConnected
                              ? () => _navigateToGoogleMeetPage()
                              : _onConnectGoogleMeetPressed),
                    onLongPress:
                        (_isConnectingGoogleMeet ||
                            (_isGoogleMeetConnected && !_isGoogleMeetDataReady))
                        ? null
                        : () {
                            if (_isGoogleMeetConnected) {
                              _showGoogleMeetOptionsDialog();
                            } else {
                              _onConnectGoogleMeetPressed();
                            }
                          },
                  ),
                  // Vault
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(
                      Icons.folder_open_rounded,
                      color: sidebarTextColor,
                    ),
                    title: const Text(
                      'Vault',
                      style: TextStyle(color: sidebarTextColor),
                    ),
                    subtitle: const Text(
                      'Access documents',
                      style: TextStyle(color: hintColor, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: userBubbleColor,
                      size: 18,
                    ),
                    onTap: () => context.push(RoutePaths.vault),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 4),
                    child: Divider(
                      color: borderColor,
                      height: 12,
                      thickness: 0.6,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      'Recent',
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._conversations
                      .where((c) {
                        if (_drawerSearchQuery.isEmpty) return true;
                        final title = (c['title'] as String?) ?? 'Conversation';
                        return title.toLowerCase().contains(
                          _drawerSearchQuery.toLowerCase(),
                        );
                      })
                      .map((c) {
                        final isActive = c['id'] == _currentConversationId;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: isActive ? userBubbleColor : hintColor,
                          ),
                          title: Text(
                            (c['title'] as String?) ?? 'Conversation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive
                                  ? userBubbleColor
                                  : sidebarTextColor,
                            ),
                          ),
                          onTap: () => _openConversation(c),
                          onLongPress: () =>
                              _confirmDeleteConversation(c['id'] as String),
                        );
                      })
                      .toList(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: userBubbleColor,
                    backgroundImage: _currentUserPhotoUrl != null
                        ? NetworkImage(_currentUserPhotoUrl!)
                        : null,
                    child: _currentUserPhotoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentUserName ?? 'You',
                      style: const TextStyle(
                        color: sidebarTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Settings icon removed by request
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
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: isLoading
          ? null
          : () {
              debugPrint('🔥 Plugin button pressed: $title');
              onTap();
            },
      onLongPress: isLoading
          ? null
          : () {
              if (onLongPress != null) {
                debugPrint('🔥 Plugin button long-pressed: $title');
                onLongPress();
              }
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
              // Clear chat button - commented out
              // GestureDetector(
              //   onTap: _showClearConfirmation,
              //   child: Container(
              //     padding: const EdgeInsets.all(8),
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Icon(
              //       Icons.cleaning_services_outlined,
              //       color: Colors.red[400],
              //       size: 20,
              //     ),
              //   ),
              // ),
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

    if (isUser) {
      // User message - right side with 20% left margin
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            // 20% left margin
            Expanded(flex: 2, child: Container()),
            // Message content (80% width)
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Hide sender name for user prompts
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F2F4),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.messageType == MessageType.image &&
                            message.metadata != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: _buildImageGrid(message.metadata!),
                          ),
                        if (message.content.isNotEmpty)
                          Text(
                            message.content,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
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
    } else {
      // Assistant message - left side (original layout)
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

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hushh PDA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (message.cost != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _formatCost(message.cost!),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: assistantBubbleColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 15,
                          color: textColor,
                          height: 1.5,
                        ),
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
                        _typingMessages[_currentTypingIndex],
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
    // Check if any sync is active that should disable chat input
    final isAnySyncActive =
        (!_isGmailDataReady && _gmailSyncStatus?.isActive == true) ||
        _isConnectingGmail ||
        (!_isGoogleMeetDataReady && _googleMeetSyncStatus?.isActive == true) ||
        _isConnectingGoogleMeet ||
        (_isPreprocessingRequired && !_isPreprocessingComplete);

    final isSendButtonEnabled =
        (_messageController.text.trim().isNotEmpty ||
            _selectedImages.isNotEmpty) &&
        !_isSendingMessage &&
        !isAnySyncActive;

    final isInputDisabled = isAnySyncActive || _isSendingMessage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: lightBackground,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Show selected images if any
            if (_selectedImages.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    // Clear all button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''} selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearAllImages,
                          child: Text(
                            'Clear all',
                            style: TextStyle(
                              fontSize: 14,
                              color: userBubbleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Images grid
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(
                              right: index < _selectedImages.length - 1 ? 8 : 0,
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeSelectedImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            // Input row
            Row(
              children: [
                // Image picker button
                Container(
                  decoration: BoxDecoration(
                    color: assistantBubbleColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.image_outlined,
                      color: textColor,
                      size: 20,
                    ),
                    onPressed: _pickImage,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isInputDisabled
                          ? assistantBubbleColor.withOpacity(0.5)
                          : assistantBubbleColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isInputDisabled
                            ? borderColor.withOpacity(0.5)
                            : borderColor,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: !isInputDisabled,
                      decoration: InputDecoration(
                        hintText: isInputDisabled
                            ? _getSyncingHintText()
                            : 'Message Hushh PDA...',
                        hintStyle: TextStyle(
                          color: isInputDisabled
                              ? hintColor.withOpacity(0.6)
                              : hintColor,
                          fontSize: 15,
                        ),
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
          ],
        ),
      ),
    );
  }

  String _formatCost(double cost) {
    if (cost < 0.001) {
      return '\$${(cost * 1000).toStringAsFixed(2)}m'; // Show in millicents
    } else if (cost < 0.01) {
      return '\$${(cost * 100).toStringAsFixed(2)}c'; // Show in cents
    } else {
      return '\$${cost.toStringAsFixed(4)}'; // Show in dollars
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateSendButtonState);
    _messageController.dispose();
    _scrollController.dispose();
    _stopTypingAnimation();
    _gmailSyncStatusSubscription?.cancel();
    _googleMeetSyncStatusSubscription?.cancel();
    _googleMeetReadinessTimer?.cancel();
    super.dispose();
  }
}
