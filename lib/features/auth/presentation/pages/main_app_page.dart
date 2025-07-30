import 'package:flutter/material.dart';
import '../../../../shared/presentation/widgets/google_style_bottom_nav.dart';
import '../../../../shared/utils/app_local_storage.dart';
import '../../../pda/presentation/pages/pda_guest_locked_page.dart';
import '../../../pda/presentation/pages/pda_simple_page.dart';
import '../../../profile/presentation/pages/profile_page_wrapper.dart';
import '../../../discover/presentation/pages/discover_page_wrapper.dart';

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

  Widget _buildDiscoverPage() {
    return const DiscoverPageWrapper();
  }

  Widget _buildPdaPage() {
    // Check if user is in guest mode
    final isGuestMode = AppLocalStorage.isGuestMode;

    if (isGuestMode) {
      return const PdaGuestLockedPage();
    } else {
      return const PdaSimplePage();
    }
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
    return const ProfilePageWrapper();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

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
