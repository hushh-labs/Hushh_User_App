import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/app_local_storage.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/routing/app_router.dart';

/// Google-style bottom navigation bar component based on your design inspiration.
class GoogleStyleBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavItem> items;
  final Function(int) onTap;
  final bool isAgentApp; // This property is kept from your original code

  const GoogleStyleBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.isAgentApp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // The outer container for shadow and background color
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 53, // Reduced from 50 to 45 to minimize gap below
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 8.0,
          ), // Increased vertical padding to 8.0 for more gap
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildNavItem(
                context: context,
                item: item,
                index: index,
                isSelected: index == currentIndex,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Builds a single navigation item.
  Widget _buildNavItem({
    required BuildContext context,
    required BottomNavItem item,
    required int index,
    required bool isSelected,
  }) {
    final isRestrictedForGuest =
        AppLocalStorage.isGuestMode && item.isRestrictedForGuest;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isRestrictedForGuest) {
          _showGuestAccessDialog(context, item.label);
          return;
        }
        onTap(index);
      },
      // Using a transparent color to ensure the gesture detector covers the whole area
      // even for unselected items.
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 8.0,
          vertical: isSelected ? 10.0 : 4.0,
        ), // Increased vertical padding for selected items
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF616180) : Colors.transparent,
          gradient: isSelected
              ? const LinearGradient(colors: [Colors.purple, Colors.pinkAccent])
              : null,
          borderRadius: BorderRadius.circular(20.0), // Slightly reduced radius
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIcon(
              item: item,
              isSelected: isSelected,
              isRestricted: isRestrictedForGuest,
            ),
            // Conditionally add spacing and the label if the item is selected
            if (isSelected) ...[
              const SizedBox(width: 6.0), // Reduced spacing
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12, // Reduced font size
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the icon for a navigation item.
  Widget _buildIcon({
    required BottomNavItem item,
    required bool isSelected,
    required bool isRestricted,
  }) {
    // Determine the icon color based on its state
    final Color iconColor = isSelected
        ? Colors.white
        : (isRestricted ? Colors.grey[400]! : const Color(0xFF616180));

    if (item.iconPath != null) {
      // Use ColorFilter for coloring SVG assets
      return SvgPicture.asset(
        item.iconPath!,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        width: 20,
        height: 20,
      );
    } else if (item.icon != null) {
      return Icon(item.icon, color: iconColor, size: 20);
    }
    // Return an empty widget if no icon is provided
    return const SizedBox.shrink();
  }

  /// Shows a dialog for guest users trying to access restricted features.
  void _showGuestAccessDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign In Required'),
          content: Text('Please sign in to access $featureName.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppLocalStorage.setGuestMode(false);
                AppRouter.router.go(RoutePaths.mainAuth);
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }
}

/// Data class for bottom navigation items (this class remains the same)
class BottomNavItem {
  final String label;
  final String? iconPath; // For SVG icons
  final IconData? icon; // For Material icons
  final bool isRestrictedForGuest;

  const BottomNavItem({
    required this.label,
    this.iconPath,
    this.icon,
    this.isRestrictedForGuest = false,
  });

  factory BottomNavItem.user({
    required String label,
    String? iconPath,
    IconData? icon,
    bool isRestrictedForGuest = false,
  }) {
    return BottomNavItem(
      label: label,
      iconPath: iconPath,
      icon: icon,
      isRestrictedForGuest: isRestrictedForGuest,
    );
  }

  factory BottomNavItem.agent({
    required String label,
    String? iconPath,
    IconData? icon,
    bool isRestrictedForGuest = false,
  }) {
    return BottomNavItem(
      label: label,
      iconPath: iconPath,
      icon: icon,
      isRestrictedForGuest: isRestrictedForGuest,
    );
  }
}
