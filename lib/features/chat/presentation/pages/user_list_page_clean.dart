import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart' as chat;
import '../../domain/entities/user_entity.dart';
import '../pages/regular_chat_page.dart';

class UserListPageClean extends StatefulWidget {
  const UserListPageClean({super.key});

  @override
  State<UserListPageClean> createState() => _UserListPageCleanState();
}

class _UserListPageCleanState extends State<UserListPageClean> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasLoadedUsers = false;

  @override
  void initState() {
    super.initState();
    // Load users and current user when page opens
    _loadUsersIfNeeded();
  }

  void _loadUsersIfNeeded() {
    final chatBloc = context.read<chat.ChatBloc>();
    final currentState = chatBloc.state;

    // Only load users if we don't have them already
    if (currentState is! chat.UsersLoadedState || !_hasLoadedUsers) {
      chatBloc.add(const chat.LoadUsersEvent());
      chatBloc.add(const chat.GetCurrentUserEvent());
      _hasLoadedUsers = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure users are loaded when dependencies change (e.g., when returning from chat)
    _loadUsersIfNeeded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      context.read<chat.ChatBloc>().add(const chat.LoadUsersEvent());
    } else {
      context.read<chat.ChatBloc>().add(chat.SearchUsersEvent(query));
    }
  }

  void _startChatWithUser(ChatUserEntity user) {
    final chatBloc = context.read<chat.ChatBloc>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      // Handle case where current user is not loaded
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not identify current user. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create a sorted list of participant IDs to ensure a consistent chat ID
    final participantIds = [currentUserId, user.id]..sort();
    final chatId = participantIds.join('_');

    // Dispatch OpenChatEvent to either create a new chat or load an existing one
    chatBloc.add(chat.OpenChatEvent(chatId));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: chatBloc,
          child: RegularChatPage(
            chatId: chatId,
            userName: user.name ?? 'Unknown User',
          ),
        ),
      ),
    );
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
        title: const Text(
          'New Chat',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // User List
          Expanded(
            child: BlocBuilder<chat.ChatBloc, chat.ChatState>(
              builder: (context, state) {
                // Show loading state only if we haven't loaded users yet
                if (state is chat.ChatLoadingState && !_hasLoadedUsers) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is chat.ChatErrorState) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _hasLoadedUsers = false;
                            context.read<chat.ChatBloc>().add(
                              const chat.LoadUsersEvent(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is chat.UsersLoadedState) {
                  final users = state.users;

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No users found'
                                : 'No users match your search',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserTile(user);
                    },
                  );
                }

                // If we're in any other state (like ChatMessagesLoadedState),
                // still show the user list if we have it cached
                if (_hasLoadedUsers) {
                  // Try to get users from the bloc's cached state
                  final chatBloc = context.read<chat.ChatBloc>();
                  // Force reload users if we don't have them in current state
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (chatBloc.state is! chat.UsersLoadedState) {
                      chatBloc.add(const chat.LoadUsersEvent());
                    }
                  });
                }

                return const Center(child: Text('No users available'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(ChatUserEntity user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startChatWithUser(user),
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
                  color: _getAvatarColor(user),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: user.profileImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          user.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Chat Button
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFA342FF),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  onPressed: () => _startChatWithUser(user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(ChatUserEntity user) {
    // Generate consistent colors based on user ID
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF607D8B),
      const Color(0xFF795548),
      const Color(0xFF9E9E9E),
    ];

    final index = user.id.hashCode.abs() % colors.length;
    return colors[index];
  }
}
