import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final VoidCallback onAttachFile;
  final Function(String)? onTextChanged;
  final Function(String)?
  onImageSelected; // Changed to String path for web compatibility
  final Function(String)?
  onFileSelected; // Changed to String path for web compatibility

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onAttachFile,
    this.onTextChanged,
    this.onImageSelected,
    this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button with dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onSelected: (value) => _handleAttachmentSelection(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'image',
                child: Row(
                  children: [
                    Icon(Icons.image, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Image'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Camera'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'file',
                child: Row(
                  children: [
                    Icon(Icons.file_copy, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('File'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (text) {
                debugPrint('MessageInput: Text changed to: "$text"');
                onTextChanged?.call(text);
              },
              onSubmitted: onSendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFA342FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => onSendMessage(controller.text),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttachmentSelection(BuildContext context, String type) async {
    switch (type) {
      case 'image':
        await _pickImage(ImageSource.gallery);
        break;
      case 'camera':
        await _pickImage(ImageSource.camera);
        break;
      case 'file':
        await _pickFile();
        break;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Use XFile path directly for web compatibility
        onImageSelected?.call(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickFile() async {
    // TODO: Implement actual file upload logic
    // For now, we'll show a placeholder message
    debugPrint('File upload feature coming soon!');
  }
}
