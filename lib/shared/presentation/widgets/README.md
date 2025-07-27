# Bottom Navigation Widget

This directory contains the `GoogleStyleBottomNav` widget, a customizable bottom navigation bar with Google Material Design styling.

## Features

- **Google Material Design**: Follows Google's Material Design guidelines
- **Guest Mode Support**: Restricts certain features for guest users
- **SVG Icon Support**: Supports both Material Icons and SVG assets
- **Smooth Animations**: Animated transitions and haptic feedback
- **Accessibility**: Proper accessibility support

## Usage

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:hushh_user_app/shared/presentation/widgets/google_style_bottom_nav.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  int _currentIndex = 0;

  final List<BottomNavItem> _bottomNavItems = [
    BottomNavItem.user(
      label: 'Discover',
      icon: Icons.explore_outlined,
    ),
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
      label: 'Settings',
      icon: Icons.settings_outlined,
      isRestrictedForGuest: false, // User guests can access settings
    ),
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Handle navigation based on index
    switch (index) {
      case 0: // Discover
        // Navigate to Discover page
        break;
      case 1: // PDA
        // Navigate to PDA page
        break;
      case 2: // Chat
        // Navigate to Chat page
        break;
      case 3: // Settings
        // Navigate to Settings page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YourPageContent(),
      bottomNavigationBar: GoogleStyleBottomNav(
        currentIndex: _currentIndex,
        items: _bottomNavItems,
        onTap: _onBottomNavTap,
        isAgentApp: false,
      ),
    );
  }
}
```

### Navigation Item Types

#### Material Icons
```dart
BottomNavItem.user(
  label: 'Discover',
  icon: Icons.explore_outlined,
)
```

#### SVG Icons
```dart
BottomNavItem.user(
  label: 'Chat',
  iconPath: 'assets/chat_bottom_bar_icon.svg',
  isRestrictedForGuest: true,
)
```

### Guest Mode Restrictions

The widget automatically handles guest mode restrictions:

- **Guest Users**: Cannot access items marked with `isRestrictedForGuest: true`
- **Authenticated Users**: Can access all features
- **Dialog Prompt**: Shows a sign-in dialog when guests try to access restricted features

### Widget Properties

| Property | Type | Description |
|----------|------|-------------|
| `currentIndex` | `int` | Currently selected tab index |
| `items` | `List<BottomNavItem>` | List of navigation items |
| `onTap` | `Function(int)` | Callback when a tab is tapped |
| `isAgentApp` | `bool` | Whether this is the agent app (affects styling) |

### BottomNavItem Properties

| Property | Type | Description |
|----------|------|-------------|
| `label` | `String` | Display text for the tab |
| `icon` | `IconData?` | Material icon (optional) |
| `iconPath` | `String?` | SVG asset path (optional) |
| `isRestrictedForGuest` | `bool` | Whether guest users can access this feature |

## Styling

The widget uses Google Material Design colors and styling:

- **Selected Tab**: Purple gradient background with white text
- **Unselected Tab**: Transparent background with gray text
- **Guest Restricted**: Grayed out appearance
- **Shadows**: Subtle elevation shadow for depth

## Dependencies

Make sure you have these dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_svg: ^2.0.9
  shared_preferences: ^2.2.2
```

## Example

See `BottomNavExample` in `lib/features/auth/presentation/pages/bottom_nav_example.dart` for a complete implementation example. 