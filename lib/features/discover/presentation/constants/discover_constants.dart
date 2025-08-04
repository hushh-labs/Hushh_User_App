import 'package:flutter/material.dart';

class DiscoverConstants {
  // Colors
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);
  static const Color lightGreyBackground = Color(0xFFF9F9F9);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color successGreen = Color(0xFF4CAF50);

  // Dimensions
  static const double searchBarHeight = 60.0;
  static const double productTileWidth = 180.0;
  static const double productTileHeight = 240.0;
  static const double agentAvatarSize = 40.0;
  static const double cartItemImageSize = 60.0;

  // Padding and Margins
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
  );
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets searchBarPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );

  // Border Radius
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 20.0;

  // Animation Durations
  static const Duration shimmerAnimationDuration = Duration(milliseconds: 1500);
  static const Duration modalCloseDelay = Duration(milliseconds: 100);

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20.0,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16.0,
    color: Colors.black87,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14.0,
    color: Colors.grey,
  );

  static const TextStyle buttonStyle = TextStyle(
    color: primaryPurple,
    fontWeight: FontWeight.bold,
  );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cartBadgeGradient = LinearGradient(
    colors: [primaryPink, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
