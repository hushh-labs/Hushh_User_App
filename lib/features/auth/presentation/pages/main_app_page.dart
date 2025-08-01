import 'package:flutter/material.dart';
import '../../../../shared/presentation/widgets/google_style_bottom_nav.dart';
import '../../../../shared/utils/app_local_storage.dart';
import '../../../pda/presentation/pages/pda_guest_locked_page.dart';
import '../../../pda/presentation/pages/pda_simple_page.dart';
import '../../../profile/presentation/pages/profile_page_wrapper.dart';
import '../../../discover/presentation/pages/discover_page_wrapper.dart';
import '../../../../shared/presentation/widgets/debug_wrapper.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DiscoverPageWrapper(),
    const PdaSimplePage(),
    const Center(child: Text('Chat')),
    const ProfilePageWrapper(),
  ];

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
    // Check if the user is in guest mode and trying to access a restricted page
    if (AppLocalStorage.isGuestMode &&
        _bottomNavItems[index].isRestrictedForGuest) {
      // Show a dialog or navigate to a locked page
      showDialog(
        context: context,
        builder: (context) => const PdaGuestLockedPage(),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DebugWrapper(child: _pages[_currentIndex]),
      bottomNavigationBar: GoogleStyleBottomNav(
        items: _bottomNavItems,
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
