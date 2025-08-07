import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../../shared/constants/firestore_constants.dart';
import '../bloc/chat_bloc.dart' as chat;
import '../pages/regular_chat_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final List<User> allUsers = [];

      // Search in HushUsers collection
      try {
        final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .get();

        final usersFromHushUsers = usersSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return User(
            id: doc.id,
            email: data[FirestoreFields.email],
            phoneNumber: data[FirestoreFields.phoneNumber],
            name:
                data['fullName'] ??
                data[FirestoreFields.name] ??
                data[FirestoreFields.displayName],
            profileImage: data[FirestoreFields.photoUrl],
            createdAt: _parseTimestamp(data[FirestoreFields.createdAt]),
            isEmailVerified: data[FirestoreFields.emailVerified] ?? false,
            isPhoneVerified: data[FirestoreFields.phoneVerified] ?? false,
          );
        }).toList();

        allUsers.addAll(usersFromHushUsers);
      } catch (e) {
        debugPrint('Error fetching from HushUsers: $e');
      }

      // Search in Hushhagents collection
      try {
        final QuerySnapshot agentsSnapshot = await FirebaseFirestore.instance
            .collection(FirestoreCollections.agents)
            .get();

        final usersFromHushhagents = agentsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return User(
            id: doc.id,
            email: data[FirestoreFields.email],
            phoneNumber:
                data[FirestoreFields.phone], // Use 'phone' field for agents
            name: data['fullName'] ?? data[FirestoreFields.name],
            profileImage: data[FirestoreFields.photoUrl],
            createdAt: _parseTimestamp(data[FirestoreFields.createdAt]),
            isEmailVerified: data[FirestoreFields.emailVerified] ?? false,
            isPhoneVerified: data[FirestoreFields.phoneVerified] ?? false,
          );
        }).toList();

        allUsers.addAll(usersFromHushhagents);
      } catch (e) {
        debugPrint('Error fetching from Hushhagents: $e');
      }

      // Filter out current user
      allUsers.removeWhere((user) => user.id == currentUser.uid);

      // Sort users by latest activity (for now, by creation date)
      allUsers.sort((a, b) {
        final dateA =
            a.createdAt ?? DateTime.now().subtract(const Duration(days: 365));
        final dateB =
            b.createdAt ?? DateTime.now().subtract(const Duration(days: 365));
        return dateB.compareTo(dateA); // Latest first
      });

      setState(() {
        _users = allUsers;
        _filteredUsers = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    final filtered = _users.where((user) {
      final name = user.name?.toLowerCase() ?? '';
      final email = user.email?.toLowerCase() ?? '';
      final phone = user.phoneNumber?.toLowerCase() ?? '';

      return name.contains(lowercaseQuery) ||
          email.contains(lowercaseQuery) ||
          phone.contains(lowercaseQuery);
    }).toList();

    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _startChatWithUser(User user) {
    // Create chat ID by combining user IDs
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = [currentUser.uid, user.id]..sort();
    final sortedChatId = chatId.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            final bloc = chat.ChatBloc();
            bloc.add(const chat.RefreshChatsEvent());
            bloc.add(
              chat.OpenChatEvent(sortedChatId),
            ); // Add the missing OpenChatEvent
            return bloc;
          },
          child: RegularChatPage(
            chatId: sortedChatId,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
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
                          _error!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredUsers.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserTile(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(User user) {
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

  Color _getAvatarColor(User user) {
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

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
      return null;
    }
  }
}
