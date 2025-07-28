// App router configuration
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/mainpage.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/phone_input_page.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/otp_verification.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/main_app_page.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/create_first_card.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/card_created_success_page.dart';
import 'package:hushh_user_app/features/auth/presentation/pages/video_recording_page.dart';
import 'package:hushh_user_app/features/pda/presentation/pages/pda_simple_page.dart';

import 'route_paths.dart';
import 'auth_guard.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RoutePaths.mainAuth,
    redirect: AuthGuard.redirect,
    routes: [
      // Main auth page
      GoRoute(
        path: RoutePaths.mainAuth,
        name: RouteNames.mainAuth,
        builder: (context, state) => const MainAuthPage(),
      ),
      // Phone input page
      GoRoute(
        path: RoutePaths.phoneInput,
        name: RouteNames.phoneInput,
        builder: (context, state) => const PhoneInputPage(),
      ),
      // OTP verification page
      GoRoute(
        path: RoutePaths.otpVerification,
        name: RouteNames.otpVerification,
        builder: (context, state) {
          final args = state.extra as OtpVerificationPageArgs;
          return OtpVerificationPage(args: args);
        },
      ),
      // Main app page (handles all tabs)
      GoRoute(
        path: RoutePaths.discover,
        name: RouteNames.discover,
        builder: (context, state) => const MainAppPage(),
      ),
      // Create first card page
      GoRoute(
        path: RoutePaths.createFirstCard,
        name: RouteNames.createFirstCard,
        builder: (context, state) {
          final args = state.extra as CreateFirstCardPageArgs?;
          return CreateFirstCardPage(args: args);
        },
      ),
      // Card created success page
      GoRoute(
        path: RoutePaths.cardCreatedSuccess,
        name: RouteNames.cardCreatedSuccess,
        builder: (context, state) => const CardCreatedSuccessPage(),
      ),
      // Video recording page
      GoRoute(
        path: RoutePaths.videoRecording,
        name: RouteNames.videoRecording,
        builder: (context, state) => const VideoRecordingPage(),
      ),
      // PDA page
      GoRoute(
        path: RoutePaths.pda,
        name: RouteNames.pda,
        builder: (context, state) => const PdaSimplePage(),
      ),
      // TODO: Add more auth routes when login/register pages are created
      // GoRoute(
      //   path: RoutePaths.login,
      //   name: RouteNames.login,
      //   builder: (context, state) => const LoginPage(),
      // ),
      // GoRoute(
      //   path: RoutePaths.register,
      //   name: RouteNames.register,
      //   builder: (context, state) => const RegisterPage(),
      // ),
      // Protected routes

      // Add more routes here as you create more features
    ],
    errorBuilder: (context, state) {
      // Redirect to main auth page instead of showing error
      return const MainAuthPage();
    },
  );
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(
        child: Text('The page you are looking for does not exist.'),
      ),
    );
  }
}
