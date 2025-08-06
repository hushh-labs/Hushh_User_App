import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart' as chat;
import '../components/message_bubble.dart';
import '../components/message_input.dart';

class HushhBotChatPage extends StatelessWidget {
  final String chatId;

  const HushhBotChatPage({super.key, this.chatId = 'hushh_bot'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => chat.ChatBloc()..add(chat.OpenChatEvent(chatId)),
      child: _HushhBotChatView(chatId: chatId),
    );
  }
}

class _HushhBotChatView extends StatefulWidget {
  final String chatId;

  const _HushhBotChatView({required this.chatId});

  @override
  State<_HushhBotChatView> createState() => _HushhBotChatViewState();
}

class _HushhBotChatViewState extends State<_HushhBotChatView> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFA342FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hushh Bot',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: BlocConsumer<chat.ChatBloc, chat.ChatState>(
        listener: (context, state) {
          if (state is chat.ChatErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          List<chat.ChatMessage> messages = [];

          if (state is chat.ChatMessagesLoadedState) {
            messages = state.messages;
          }

          return Column(
            children: [
              // Messages
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isLastMessage = index == messages.length - 1;
                          return MessageBubble(
                            message: message,
                            isLastMessage: isLastMessage,
                          );
                        },
                      ),
              ),

              // Message Input
              if (state is chat.FileUploadingState)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Uploading and analyzing file...'),
                    ],
                  ),
                )
              else
                MessageInput(
                  controller: _messageController,
                  onSendMessage: _sendMessage,
                  onAttachFile: _attachFile,
                ),
            ],
          );
        },
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    context.read<chat.ChatBloc>().add(
      chat.SendMessageEvent(chatId: widget.chatId, message: text, isBot: false),
    );

    _messageController.clear();
  }

  void _attachFile() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFFA342FF),
              ),
              title: const Text('Upload Bill Image'),
              onTap: () {
                Navigator.pop(context);
                _handleFileUpload('image');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFFA342FF)),
              title: const Text('Upload Bill PDF'),
              onTap: () {
                Navigator.pop(context);
                _handleFileUpload('pdf');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleFileUpload(String fileType) {
    context.read<chat.ChatBloc>().add(
      chat.UploadFileEvent(chatId: widget.chatId, fileType: fileType),
    );
  }
}
