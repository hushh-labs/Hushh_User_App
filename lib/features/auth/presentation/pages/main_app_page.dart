import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/presentation/widgets/google_style_bottom_nav.dart';
import '../../../../shared/utils/app_local_storage.dart';
// import '../../../pda/presentation/pages/pda_chatgpt_style_page.dart';
import '../../../profile/presentation/pages/profile_page_wrapper.dart';
import '../../../discover_revamp/presentation/pages/discover_revamp_wrapper.dart';
// import '../../../discover_revamp/presentation/pages/discover_revamp_wrapper.dart';
import '../../../chat/presentation/pages/chat_page_wrapper.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart' as chat;
import '../../../../shared/presentation/widgets/debug_wrapper.dart';
import '../../../../shared/utils/guest_access_control.dart';
import '../../../kai/presentation/pages/kai_page_wrapper.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DiscoverRevampWrapper(),
    const KaiPageWrapper(),
    const ChatPageWrapper(),
    const ProfilePageWrapper(),
  ];

  final List<BottomNavItem> _bottomNavItems = [
    BottomNavItem.user(label: 'Discover', icon: Icons.explore_outlined),
    BottomNavItem.user(label: 'Kai', icon: Icons.auto_awesome),
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
      // Show guest access popup
      GuestAccessControl.showGuestAccessPopup(
        context,
        featureName: _bottomNavItems[index].label,
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => chat.ChatBloc()..add(const chat.RefreshChatsEvent()),
      child: Scaffold(
        extendBody: true, // allow bottom bar to float over transparent area
        body: DebugWrapper(child: _pages[_currentIndex]),
        bottomNavigationBar: GoogleStyleBottomNav(
          items: _bottomNavItems,
          currentIndex: _currentIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }
}
