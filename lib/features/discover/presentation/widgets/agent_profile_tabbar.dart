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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TabBar(
        controller: tabController,
        onTap: onTap,
        indicator: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.white,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Color(0xFF666666),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF666666),
        dividerColor: Colors.transparent,
        tabs: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 18),
                SizedBox(width: 6),
                Text("Products"),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 18),
                SizedBox(width: 6),
                Text("Lookbooks"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
