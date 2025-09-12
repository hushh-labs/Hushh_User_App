import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/chat_bloc.dart';
import '../../domain/entities/chat_entity.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isLastMessage;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? _userDisplayName;
  bool _isLoadingName = false;

  @override
  void initState() {
    super.initState();
    if (!widget.message.isBot &&
        widget.message.senderId != FirebaseAuth.instance.currentUser?.uid) {
      _loadUserDisplayName();
    }
  }

  Future<void> _loadUserDisplayName() async {
    if (_isLoadingName) return;

    setState(() {
      _isLoadingName = true;
    });

    try {
      // First try to get user from HushUsers collection
      final userDoc = await FirebaseFirestore.instance
          .collection('HushUsers')
          .doc(widget.message.senderId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userName =
            userData['fullName'] ?? userData['name'] ?? userData['displayName'];
        if (userName != null) {
          setState(() {
            _userDisplayName = userName;
            _isLoadingName = false;
          });
          return;
        }
      }

      // If not found in HushUsers, try Hushhagents collection
      final agentDoc = await FirebaseFirestore.instance
          .collection('Hushhagents')
          .doc(widget.message.senderId)
          .get();

      if (agentDoc.exists) {
        final agentData = agentDoc.data()!;
        final agentName = agentData['fullName'] ?? agentData['name'];
        if (agentName != null) {
          setState(() {
            _userDisplayName = agentName;
            _isLoadingName = false;
          });
          return;
        }
      }

      // Fallback to shortened user ID
      setState(() {
        _userDisplayName = _getFallbackName(widget.message.senderId);
        _isLoadingName = false;
      });
    } catch (e) {
      print('Error loading user display name: $e');
      setState(() {
        _userDisplayName = _getFallbackName(widget.message.senderId);
        _isLoadingName = false;
      });
    }
  }

  String _getFallbackName(String userId) {
    if (userId.length > 8) {
      return 'User ${userId.substring(0, 8)}...';
    }
    return 'User $userId';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    // Split by space and get first letter of each word
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.length == 1 && words[0].length >= 2) {
      return words[0].substring(0, 2).toUpperCase();
    } else if (words.length == 1 && words[0].length == 1) {
      return words[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isFromCurrentUser = widget.message.senderId == currentUserId;
    final isBot = widget.message.isBot;

    // Determine if message should be aligned to the right (current user) or left (other user/bot)
    final isRightAligned = isFromCurrentUser || isBot;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isRightAligned
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isRightAligned) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isBot
                  ? const Color(0xFFA342FF)
                  : _getAvatarColor(widget.message.senderId),
              child: isBot
                  ? Icon(Icons.smart_toy, color: Colors.white, size: 16)
                  : _isLoadingName
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _getInitials(
                        _userDisplayName ??
                            _getFallbackName(widget.message.senderId),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isRightAligned
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isRightAligned
                        ? const Color(0xFFA342FF)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _buildMessageContent(isRightAligned),
                ),
                // Seen indicator only for the last message and only for current user's messages
                if (widget.isLastMessage && isFromCurrentUser) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.message.isSeen) ...[
                          Text(
                            'seen',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                        ] else ...[
                          Icon(Icons.done, size: 14, color: Colors.grey[400]),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isRightAligned) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
      const Color(0xFF009688), // Teal
    ];
    final index = userId.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildMessageContent(bool isRightAligned) {
    switch (widget.message.type) {
      case MessageType.image:
        return _buildImageMessage(isRightAligned);
      case MessageType.video:
        return _buildVideoMessage(isRightAligned);
      case MessageType.audio:
        return _buildAudioMessage(isRightAligned);
      case MessageType.file:
        return _buildFileMessage(isRightAligned);
      case MessageType.text:
        return _buildTextMessage(isRightAligned);
    }
  }

  // Helper method to check if message has both text and image
  bool _hasTextAndImage() {
    return widget.message.type == MessageType.image && 
           widget.message.text.isNotEmpty;
  }

  Widget _buildTextMessage(bool isRightAligned) {
    return Text(
      widget.message.text,
      style: TextStyle(
        color: isRightAligned ? Colors.white : Colors.black,
        fontSize: 14,
      ),
    );
  }

  Widget _buildImageMessage(bool isRightAligned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.message.text,
              style: TextStyle(
                color: isRightAligned ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRightAligned
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImageWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    // Check if message has image data or URL
    if (widget.message.imageData != null) {
      return Image.memory(
        Uint8List.fromList(widget.message.imageData!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      );
    } else if (widget.message.imageUrl != null) {
      return Image.network(
        widget.message.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      );
    } else {
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey[300],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
  }

  Widget _buildVideoMessage(bool isRightAligned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.message.text,
              style: TextStyle(
                color: isRightAligned ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: const Center(
            child: Icon(Icons.videocam, color: Colors.grey, size: 48),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioMessage(bool isRightAligned) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_arrow,
          color: isRightAligned ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 8),
        Text(
          'Audio Message',
          style: TextStyle(
            color: isRightAligned ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage(bool isRightAligned) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.attach_file,
          color: isRightAligned ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.message.text.isNotEmpty ? widget.message.text : 'File',
            style: TextStyle(
              color: isRightAligned ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
