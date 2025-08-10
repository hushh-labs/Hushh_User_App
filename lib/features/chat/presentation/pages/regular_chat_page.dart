import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/chat_bloc.dart' as chat;
import '../../domain/entities/chat_entity.dart';
import '../components/message_bubble.dart';
import '../components/message_input.dart';
import 'dart:async'; // Added for Timer

class RegularChatPage extends StatefulWidget {
  final String chatId;
  final String userName;

  const RegularChatPage({
    super.key,
    required this.chatId,
    required this.userName,
  });

  @override
  State<RegularChatPage> createState() => _RegularChatPageState();
}

class _RegularChatPageState extends State<RegularChatPage> {
  final TextEditingController _messageController = TextEditingController();
  late String _currentChatId;
  bool _isTyping = false;
  bool _hasSentFirstMessage = false; // Track if first message has been sent
  Timer? _typingTimer;
  bool _hasBlockedUser =
      false; // Track if current user has blocked the other user

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    // Start listening for typing status of the other user
    _startListeningTypingStatus();
    // Check blocking status
    _checkBlockingStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingTimer?.cancel();
    // Stop typing when leaving the page
    if (_isTyping) {
      _setTypingStatus(false);
    }
    super.dispose();
  }

  void _startListeningTypingStatus() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final participants = _currentChatId.split('_');
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return;

    context.read<chat.ChatBloc>().add(
      chat.ListenTypingStatusEvent(_currentChatId, otherUserId),
    );
  }

  void _checkBlockingStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final participants = _currentChatId.split('_');
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return;

    // Check if current user has blocked the other user
    final chatBloc = context.read<chat.ChatBloc>();
    chatBloc.add(
      chat.CheckBlockingStatusEvent(
        userId: currentUserId,
        otherUserId: otherUserId,
      ),
    );
  }

  void _checkForExistingMessages() {
    // Check if there are existing messages in the chat
    // If so, enable typing status immediately
    final chatBloc = context.read<chat.ChatBloc>();
    // This will be handled by the BLoC state updates
  }

  void _setTypingStatus(bool isTyping) {
    print('🔍 UI: _setTypingStatus called');
    print('🔍 UI: Is typing: $isTyping');
    print('🔍 UI: Chat ID: ${_currentChatId}');

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print('❌ UI: Current user is null, cannot set typing status');
      return;
    }

    print('🔍 UI: Current user ID: $currentUserId');

    context.read<chat.ChatBloc>().add(
      chat.SetTypingStatusEvent(_currentChatId, currentUserId, isTyping),
    );
    print('🔍 UI: SetTypingStatusEvent added to BLoC');
  }

  void _onTextChanged(String text) {
    print('🔍 UI: _onTextChanged called');
    print('🔍 UI: Text: "$text" (length: ${text.length})');
    print('🔍 UI: Current typing status: $_isTyping');
    print('🔍 UI: Has sent first message: $_hasSentFirstMessage');

    // Only set typing status if first message has been sent
    if (!_hasSentFirstMessage) {
      print('🔍 UI: First message not sent yet - skipping typing status');
      return;
    }

    if (!_isTyping && text.isNotEmpty) {
      print('🔍 UI: Starting typing - setting status to true');
      _isTyping = true;
      _setTypingStatus(true);
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_isTyping) {
        print('🔍 UI: Typing timeout - setting status to false');
        _isTyping = false;
        _setTypingStatus(false);
      }
    });
  }

  void _onImageSelected(File imageFile) async {
    try {
      // Convert file to bytes for sending
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Send image message
      context.read<chat.ChatBloc>().add(
        chat.SendMessageEvent(
          chatId: _currentChatId,
          message: 'Image',
          isBot: false,
          messageType: MessageType.image,
          imageData: imageBytes.toList(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onFileSelected(File file) async {
    try {
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File upload not available for regular chats'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<chat.ChatBloc>().add(const chat.RefreshChatsEvent());
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              context.read<chat.ChatBloc>().add(const chat.RefreshChatsEvent());
              // Navigate back to the chat list
              Navigator.of(context).pop();
            },
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(_currentChatId),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleChatOption(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_chat',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Clear Chat'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _hasBlockedUser ? 'unblock_user' : 'block_user',
                  child: Row(
                    children: [
                      Icon(
                        _hasBlockedUser ? Icons.check_circle : Icons.block,
                        color: _hasBlockedUser ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(_hasBlockedUser ? 'Unblock User' : 'Block User'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: BlocConsumer<chat.ChatBloc, chat.ChatState>(
          buildWhen: (previous, current) {
            return current is chat.ChatMessagesLoadedState ||
                current is chat.ChatLoadingState;
          },
          listener: (context, state) {
            print('🔍 UI: BlocListener called');
            print('🔍 UI: State type: ${state.runtimeType}');

            if (state is chat.ChatErrorState) {
              print('❌ UI: ChatErrorState received: ${state.message}');

              // Check if this is a blocking error that requires user action
              if (state.message.contains('You have blocked') &&
                  state.message.contains('Unblock to send messages')) {
                // Current user has blocked the other user - show unblock dialog
                _showUnblockDialog(context, state.message);
              } else if (state.message.contains('You have been blocked by')) {
                // Current user has been blocked by the other user - show info dialog
                _showBlockedByUserDialog(context, state.message);
              } else {
                // Other errors - show snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            if (state is chat.UserBlockedState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User has been blocked successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // Update the blocking status
              setState(() {
                _hasBlockedUser = true;
              });
            }

            if (state is chat.UserUnblockedState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User has been unblocked successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // Update the blocking status
              setState(() {
                _hasBlockedUser = false;
              });
            }

            if (state is chat.BlockingStatusCheckedState) {
              setState(() {
                _hasBlockedUser = state.hasBlockedUser;
              });
            }

            if (state is chat.ChatMessagesLoadedState) {
              print('🔍 UI: ChatMessagesLoadedState received in listener');
              print('🔍 UI: Messages count: ${state.messages.length}');
              print('🔍 UI: Is other user typing: ${state.isOtherUserTyping}');
              print('🔍 UI: Has sent first message: $_hasSentFirstMessage');

              if (state.messages.isNotEmpty && !_hasSentFirstMessage) {
                print(
                  '🔍 UI: Existing messages found - enabling typing status',
                );
                _hasSentFirstMessage = true;
              }

              if (state.chatId != _currentChatId) {
                setState(() {
                  _currentChatId = state.chatId;
                });
              }
            }
          },
          builder: (context, state) {
            print('🔍 UI: BlocBuilder called');
            print('🔍 UI: State type: ${state.runtimeType}');
            print('🔍 UI: State hash: ${state.hashCode}');
            print('🔍 UI: Current chat ID: ${_currentChatId}');
            print('🔍 UI: State details: $state');

            if (state is chat.ChatLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is chat.ChatMessagesLoadedState) {
              final messages = state.messages;
              final isOtherUserTyping = state.isOtherUserTyping;

              print('🔍 UI: ChatMessagesLoadedState received');
              print('🔍 UI: Messages count: ${messages.length}');
              print('🔍 UI: Is other user typing: $isOtherUserTyping');
              print('🔍 UI: Chat ID: ${state.chatId}');
              print('🔍 UI: Expected chat ID: ${_currentChatId}');
              print('🔍 UI: Chat IDs match: ${state.chatId == _currentChatId}');

              for (int i = 0; i < messages.length; i++) {
                print(
                  '🔍 UI: Message $i: "${messages[i].text}" (ID: ${messages[i].id})',
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Send the first message to start the conversation!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 16,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isLastMessage =
                                  index == messages.length - 1;
                              return MessageBubble(
                                message: message,
                                isLastMessage: isLastMessage,
                              );
                            },
                          ),
                  ),
                  if (isOtherUserTyping)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${widget.userName} is typing',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey[600]!,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  MessageInput(
                    controller: _messageController,
                    onSendMessage: _sendMessage,
                    onTextChanged: _onTextChanged,
                    onImageSelected: _onImageSelected,
                    onFileSelected: _onFileSelected,
                    onAttachFile: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'File upload not available for regular chats',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Stop typing when sending message
    if (_isTyping) {
      _isTyping = false;
      _setTypingStatus(false);
    }

    context.read<chat.ChatBloc>().add(
      chat.SendMessageEvent(
        chatId: _currentChatId,
        message: text.trim(),
        isBot: false,
      ),
    );

    _messageController.clear();
    _hasSentFirstMessage = true; // Mark that the first message has been sent
  }

  Color _getAvatarColor(String chatId) {
    // Generate consistent colors based on chat ID
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
    ];

    final index = chatId.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _handleChatOption(BuildContext context, String value) {
    switch (value) {
      case 'clear_chat':
        _showClearChatDialog(context);
        break;
      case 'block_user':
        _showBlockUserDialog(context);
        break;
      case 'unblock_user':
        _showUnblockUserDialog(context);
        break;
    }
  }

  void _showClearChatDialog(BuildContext context) {
    // Capture the ChatBloc instance before showing the dialog
    final chatBloc = context.read<chat.ChatBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Chat'),
          content: const Text(
            'Are you sure you want to clear this chat? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == null) return;
                chatBloc.add(
                  chat.ClearChatEvent(
                    chatId: _currentChatId,
                    userId: currentUserId,
                  ),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showBlockUserDialog(BuildContext context) {
    // Capture the ChatBloc instance before showing the dialog
    final chatBloc = context.read<chat.ChatBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Block User'),
          content: Text(
            'Are you sure you want to block ${widget.userName}? You will no longer receive messages from this user.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == null) return;

                final participants = _currentChatId.split('_');
                final otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );

                if (otherUserId.isEmpty) return;

                chatBloc.add(
                  chat.BlockUserEvent(
                    userId: currentUserId,
                    blockedUserId: otherUserId,
                  ),
                );
              },
              child: const Text('Block', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showUnblockDialog(BuildContext context, String message) {
    // Capture the ChatBloc instance before showing the dialog
    final chatBloc = context.read<chat.ChatBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('User Blocked'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == null) return;

                final participants = _currentChatId.split('_');
                final otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );

                if (otherUserId.isEmpty) return;

                chatBloc.add(
                  chat.UnblockUserEvent(
                    userId: currentUserId,
                    blockedUserId: otherUserId,
                  ),
                );
              },
              child: const Text(
                'Unblock',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBlockedByUserDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cannot Send Message'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showUnblockUserDialog(BuildContext context) {
    // Capture the ChatBloc instance before showing the dialog
    final chatBloc = context.read<chat.ChatBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Unblock User'),
          content: Text(
            'Are you sure you want to unblock ${widget.userName}? You will be able to receive messages from this user again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == null) return;

                final participants = _currentChatId.split('_');
                final otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );

                if (otherUserId.isEmpty) return;

                chatBloc.add(
                  chat.UnblockUserEvent(
                    userId: currentUserId,
                    blockedUserId: otherUserId,
                  ),
                );
              },
              child: const Text(
                'Unblock',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }
}
