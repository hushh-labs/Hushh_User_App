import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../shared/presentation/widgets/google_style_bottom_nav.dart';
import '../../../../shared/presentation/widgets/debug_wrapper.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int _currentIndex = 2; // Chat is third tab

  final List<BottomNavItem> _bottomNavItems = [
    BottomNavItem.user(label: 'Discover', icon: Icons.explore_outlined),
    BottomNavItem.user(
      label: 'PDA',
      icon: Icons.psychology_outlined,
      isRestrictedForGuest: true, // User guests cannot access PDA
    ),
    BottomNavItem.user(
      label: 'Chat',
      iconPath: 'assets/chat_bottom_bar_icon.svg',
      isRestrictedForGuest: true, // User guests cannot access chat
    ),
    BottomNavItem.user(
      label: 'Profile',
      icon: Icons.person_outline,
      isRestrictedForGuest: false, // User guests can access profile
    ),
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0: // Discover
        context.go('/discover');
        break;
      case 1: // PDA
        context.go('/pda');
        break;
      case 2: // Chat - already on this page
        break;
      case 3: // Profile
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(SignOutEvent());
            },
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: DebugWrapper(
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 100, color: Colors.green),
              SizedBox(height: 20),
              Text(
                'Chat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Connect with others and start conversations!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
              Text(
                'Features:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '• Real-time messaging\n'
                '• Group chats\n'
                '• Voice messages\n'
                '• File sharing',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GoogleStyleBottomNav(
        currentIndex: _currentIndex,
        items: _bottomNavItems,
        onTap: _onBottomNavTap,
        isAgentApp: false,
      ),
    );
  }
}
