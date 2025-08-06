import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/chat_bloc.dart' as chat;
import '../components/chat_search_bar.dart';
import '../components/chat_list_item.dart';
import '../components/empty_chat_state.dart';
import '../../../../../shared/utils/guest_utils.dart';
import 'hushh_bot_chat_page.dart';
import 'user_list_page.dart';
import 'regular_chat_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => chat.ChatBloc()..add(const chat.LoadChatsEvent()),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              'Chats',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserListPage()),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 24),
              ),
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
          if (state is chat.ChatLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          List<chat.ChatItem> chats = [];

          if (state is chat.ChatsLoadedState) {
            chats = state.filteredChats;
          }

          return Column(
            children: [
              // Search Bar
              ChatSearchBar(
                controller: _searchController,
                onChanged: (query) {
                  GuestUtils.executeWithGuestCheck(
                    context,
                    'Chat Search',
                    () => context.read<chat.ChatBloc>().add(
                      chat.SearchChatsEvent(query),
                    ),
                  );
                },
              ),

              // Chat List
              Expanded(
                child: chats.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: EmptyChatState(),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          return Dismissible(
                            key: Key(chat.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await _showDeleteChatDialog(context, chat);
                            },
                            onDismissed: (direction) {
                              _deleteChat(chat);
                            },
                            child: ChatListItem(
                              chatItem: chat,
                              onTap: () => GuestUtils.executeWithGuestCheck(
                                context,
                                'Chat Messages',
                                () => _openChat(context, chat),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, chat.ChatItem chatItem) {
    if (chatItem.isBot && chatItem.id == 'hushh_bot') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HushhBotChatPage(chatId: chatItem.id),
        ),
      );
    } else {
      // Navigate to regular chat page for user conversations
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) {
              final bloc = chat.ChatBloc();
              // Load chats and immediately load the specific chat messages
              bloc.add(const chat.LoadChatsEvent());
              bloc.add(chat.OpenChatEvent(chatItem.id));
              return bloc;
            },
            child: RegularChatPage(
              chatId: chatItem.id,
              userName: chatItem.title,
            ),
          ),
        ),
      );
    }
  }

  Future<bool> _showDeleteChatDialog(
    BuildContext context,
    chat.ChatItem chatItem,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: Text(
            'Are you sure you want to delete the chat with ${chatItem.title}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _deleteChat(chat.ChatItem chatItem) {
    // First clear the chat messages
    context.read<chat.ChatBloc>().add(
      chat.ClearChatEvent(
        chatId: chatItem.id,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
    );

    // Then remove from chat list
    context.read<chat.ChatBloc>().add(
      chat.RemoveChatFromListEvent(chatItem.id),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat with ${chatItem.title} deleted.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
