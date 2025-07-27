import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../../../../shared/presentation/widgets/google_style_bottom_nav.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _currentIndex = 0;

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
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildDiscoverPage();
      case 1:
        return _buildPdaPage();
      case 2:
        return _buildChatPage();
      case 3:
        return _buildProfilePage();
      default:
        return _buildDiscoverPage();
    }
  }

  String _getCurrentTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Discover';
      case 1:
        return 'PDA';
      case 2:
        return 'Chat';
      case 3:
        return 'Profile';
      default:
        return 'Discover';
    }
  }

  Widget _buildDiscoverPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore, size: 100, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            'Discover Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Explore new content and features here!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPdaPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 100, color: Colors.purple),
          SizedBox(height: 20),
          Text(
            'Personal Digital Assistant',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Your AI-powered assistant is here to help!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 30),
          Text(
            'Features:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            '• Smart recommendations\n'
            '• Voice commands\n'
            '• Task automation\n'
            '• Personal insights',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPage() {
    return const Center(
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
    );
  }

  Widget _buildProfilePage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.orange,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Manage your account and preferences!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 30),
          Text(
            'Features:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            '• Account settings\n'
            '• Privacy controls\n'
            '• Notification preferences\n'
            '• Personal information',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
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
        title: Text(
          _getCurrentTitle(),
          style: const TextStyle(
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
      body: _buildCurrentPage(),
      bottomNavigationBar: GoogleStyleBottomNav(
        currentIndex: _currentIndex,
        items: _bottomNavItems,
        onTap: _onBottomNavTap,
        isAgentApp: false,
      ),
    );
  }
}
