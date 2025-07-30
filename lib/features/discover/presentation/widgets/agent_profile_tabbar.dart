import 'package:flutter/material.dart';

class AgentProfileTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Function(int) onTap;
  final TabController tabController;

  const AgentProfileTabBar({
    super.key,
    required this.onTap,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: TabBar(
        controller: tabController,
        onTap: onTap,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Colors.black,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 15,
          color: Color(0xFFC0C0C0),
        ),
        tabs: [
          const Tab(text: "Lookbooks"),
          const Tab(text: "Products"),
        ],
        dividerColor: const Color(0xFFe8d1d6),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
