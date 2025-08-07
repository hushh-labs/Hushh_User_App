import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/chat_bloc.dart' as chat;
import '../components/chat_search_bar.dart';
import '../components/chat_list_item.dart';
import '../components/empty_chat_state.dart';
import '../components/chat_loading_animation.dart';
import '../../../../../shared/utils/guest_utils.dart';
import 'hushh_bot_chat_page.dart';
import 'user_list_page_clean.dart';
import 'regular_chat_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ChatView();
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
  void initState() {
    super.initState();
    // Ensure chats are loaded when the page is first accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<chat.ChatBloc>().add(const chat.RefreshChatsEvent());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<chat.ChatBloc>(),
                        child: const UserListPageClean(),
                      ),
                    ),
                  ).then((_) {
                    context
                        .read<chat.ChatBloc>()
                        .add(const chat.RefreshChatsEvent());
                  });
                },
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
          buildWhen: (previous, current) {
            return current is chat.ChatLoadingState ||
                current is chat.ChatsLoadedState;
          },
          listener: (context, state) {
            print('🔍 UI: State changed to: ${state.runtimeType}');
            if (state is chat.ChatsLoadedState) {
              print('🔍 UI: ChatsLoadedState with ${state.chats.length} chats');
              print(
                '🔍 UI: Chat IDs: ${state.chats.map((c) => c.id).join(', ')}',
              );
            }
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
              return const ChatLoadingAnimation();
            }

            List<chat.ChatItem> chats = [];

            if (state is chat.ChatsLoadedState) {
              chats = state.filteredChats;
            }

            return Column(
              children: [
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
                            final chatItem = chats[index];

                            return Dismissible(
                              key: Key(chatItem.id),
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
                                return await _showDeleteChatDialog(
                                    context, chatItem);
                              },
                              onDismissed: (direction) {
                                _deleteChat(chatItem);
                              },
                              child: ChatListItem(
                                chatItem: chatItem,
                                onTap: () => GuestUtils.executeWithGuestCheck(
                                  context,
                                  'Chat Messages',
                                  () => _openChat(context, chatItem),
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
      ),
    );
  }

  void _openChat(BuildContext context, chat.ChatItem chatItem) {
    final chatBloc = context.read<chat.ChatBloc>();
    if (chatItem.isBot && chatItem.id == 'hushh_bot') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HushhBotChatPage(chatId: chatItem.id),
        ),
      );
    } else {
      // Navigate to regular chat page for user conversations
      chatBloc.add(chat.OpenChatEvent(chatItem.id));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: chatBloc,
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
