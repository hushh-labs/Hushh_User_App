import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../bloc/chat_bloc.dart';
import '../../domain/entities/chat_entity.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLastMessage;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (message.isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFA342FF),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isBot
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isBot
                        ? Colors.grey[200]
                        : const Color(0xFFA342FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _buildMessageContent(),
                ),
                // Seen indicator only for the last message
                if (isLastMessage) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isSeen) ...[
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
          if (!message.isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.audio:
        return _buildAudioMessage();
      case MessageType.file:
        return _buildFileMessage();
      case MessageType.text:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return Text(
      message.text,
      style: TextStyle(
        color: message.isBot ? Colors.black : Colors.white,
        fontSize: 14,
      ),
    );
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isBot ? Colors.black : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: message.isBot
                  ? Colors.grey[300]!
                  : Colors.white.withValues(alpha: 0.3),
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
    if (message.imageData != null) {
      return Image.memory(
        Uint8List.fromList(message.imageData!),
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
    } else if (message.imageUrl != null) {
      return Image.network(
        message.imageUrl!,
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

  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isBot ? Colors.black : Colors.white,
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

  Widget _buildAudioMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_arrow,
          color: message.isBot ? Colors.black : Colors.white,
        ),
        const SizedBox(width: 8),
        Text(
          'Audio Message',
          style: TextStyle(
            color: message.isBot ? Colors.black : Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.attach_file,
          color: message.isBot ? Colors.black : Colors.white,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message.text.isNotEmpty ? message.text : 'File',
            style: TextStyle(
              color: message.isBot ? Colors.black : Colors.white,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
