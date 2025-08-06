import 'package:flutter/material.dart';
import '../bloc/chat_bloc.dart';

class ChatListItem extends StatelessWidget {
  final ChatItem chatItem;
  final VoidCallback onTap;

  const ChatListItem({super.key, required this.chatItem, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAvatarColor(chatItem.avatarColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAvatarIcon(chatItem.avatarIcon),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Chat Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          chatItem.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: chatItem.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        if (chatItem.lastMessageTime != null &&
                            chatItem.lastMessageTime!.isNotEmpty)
                          Text(
                            chatItem.lastMessageTime!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatItem.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: chatItem.isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: chatItem.isUnread
                                  ? Colors.black
                                  : Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chatItem.isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFA342FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else if (chatItem.isLastMessageSeen != null &&
                            chatItem.isLastMessageSeen! &&
                            !chatItem.isBot) ...[
                          const SizedBox(width: 8),
                          Text(
                            'seen',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String colorString) {
    switch (colorString) {
      case '#A342FF':
        return const Color(0xFFA342FF);
      case '#4CAF50':
        return const Color(0xFF4CAF50);
      case '#2196F3':
        return const Color(0xFF2196F3);
      case '#FF9800':
        return const Color(0xFFFF9800);
      case '#9C27B0':
        return const Color(0xFF9C27B0);
      case '#F44336':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFA342FF);
    }
  }

  IconData _getAvatarIcon(String iconString) {
    switch (iconString) {
      case 'smart_toy':
        return Icons.smart_toy;
      case 'person':
      default:
        return Icons.person;
    }
  }
}
