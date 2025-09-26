import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A wrapper that constrains the app to mobile-width on desktop web
/// while keeping full-width on mobile web and native apps.
class ResponsiveWebWrapper extends StatelessWidget {
  final Widget child;
  final double mobileBreakpoint;
  final double maxMobileWidth;

  const ResponsiveWebWrapper({
    super.key,
    required this.child,
    this.mobileBreakpoint = 768.0,
    this.maxMobileWidth = 480.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final shouldConstrainToMobile =
            kIsWeb && screenWidth > mobileBreakpoint;

        if (shouldConstrainToMobile) {
          // Desktop web: constrain to mobile width and center
          return Container(
            color: const Color(0xFFF0F0F0), // Light gray background for desktop
            child: Center(
              child: Container(
                width: maxMobileWidth,
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        } else {
          // Mobile web or native app: use full width
          return child;
        }
      },
    );
  }
}

/// Utility class for responsive web detection
class ResponsiveHelper {
  /// Checks if we're on desktop web (web platform with wide screen)
  static bool isDesktopWeb(BuildContext context, {double breakpoint = 768.0}) {
    if (!kIsWeb) return false;
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > breakpoint;
  }

  /// Checks if we're on mobile web (web platform with narrow screen)
  static bool isMobileWeb(BuildContext context, {double breakpoint = 768.0}) {
    if (!kIsWeb) return false;
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth <= breakpoint;
  }

  /// Checks if we're on native mobile app
  static bool isNativeMobile() {
    return !kIsWeb;
  }

  /// Gets the appropriate container width for the current platform
  static double getContainerWidth(
    BuildContext context, {
    double mobileBreakpoint = 768.0,
    double maxMobileWidth = 414.0,
  }) {
    if (isDesktopWeb(context, breakpoint: mobileBreakpoint)) {
      return maxMobileWidth;
    }
    return MediaQuery.of(context).size.width;
  }
}
