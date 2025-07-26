// App router configuration
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import '../../features/Auth/presentation/pages/main_page.dart';
// import '../../features/auth/presentation/pages/phone_login_page.dart';
// import '../../features/auth/presentation/pages/otp_verification_page.dart';

import 'route_paths.dart';
import 'auth_guard.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.mainAuth,
    redirect: AuthGuard.redirect,
    routes: [
      // Main auth page
      // GoRoute(
      //   path: RoutePaths.mainAuth,
      //   name: RouteNames.mainAuth,
      //   builder: (context, state) => const MainAuthPage(),
      // ),
      // // Phone login page
      // GoRoute(
      //   path: RoutePaths.phoneLogin,
      //   name: RouteNames.phoneLogin,
      //   builder: (context, state) => const PhoneLoginPage(),
      // ),
      // // OTP verification page
      // GoRoute(
      //   path: RoutePaths.otpVerification,
      //   name: RouteNames.otpVerification,
      //   builder: (context, state) {
      //     final phoneNumber = state.extra as String? ?? '+91 9876543210';
      //     return OtpVerificationPage(phoneNumber: phoneNumber);
      //   },
      // ),
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
    errorBuilder: (context, state) => const ErrorPage(),
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
