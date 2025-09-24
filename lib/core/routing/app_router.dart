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
import 'package:hushh_user_app/features/pda/presentation/pages/pda_chatgpt_style_page.dart';
import 'package:hushh_user_app/features/vault/presentation/pages/vault_page.dart';
import 'package:hushh_user_app/features/pda/presentation/pages/gmail_page.dart';
import 'package:hushh_user_app/features/vault/presentation/bloc/vault_bloc.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/pages/qna_page.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/bloc/qna_bloc.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/pages/search_result_revamp_page.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/pages/cart_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/pages/agent_profile_revamp_page.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/bloc/agent_profile_bloc.dart';
import 'package:hushh_user_app/features/discover_revamp/domain/usecases/get_agent_profile_content.dart';

import 'route_paths.dart';
import 'auth_guard.dart';

class QnAPageArgs {
  final String agentId;
  final String agentName;

  QnAPageArgs({required this.agentId, required this.agentName});
}

class SearchResultPageArgs {
  final String? query;
  final List<String>? filters;

  SearchResultPageArgs({this.query, this.filters});
}

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
        builder: (context, state) => const PdaChatGptStylePage(),
      ),
      // Vault page
      GoRoute(
        path: RoutePaths.vault,
        name: RouteNames.vault,
        builder: (context, state) => BlocProvider(
          create: (context) => GetIt.instance<VaultBloc>(),
          child: const VaultPage(),
        ),
      ),

      // Gmail page
      GoRoute(
        path: RoutePaths.gmail,
        name: 'gmail',
        builder: (context, state) => const GmailPage(),
      ),

      // Q&A page
      GoRoute(
        path: RoutePaths.qna,
        name: RouteNames.qna,
        builder: (context, state) {
          final args = state.extra as QnAPageArgs;
          return BlocProvider(
            create: (context) => GetIt.instance<QnABloc>(),
            child: QnAPage(agentId: args.agentId, agentName: args.agentName),
          );
        },
      ),

      // Search Results page
      GoRoute(
        path: RoutePaths.searchResults,
        name: RouteNames.searchResults,
        builder: (context, state) {
          final args = state.extra as SearchResultPageArgs?;
          return SearchResultRevampPage(
            initialQuery: args?.query,
            selectedFilters: args?.filters,
          );
        },
      ),

      // Cart page
      GoRoute(
        path: RoutePaths.cart,
        name: RouteNames.cart,
        builder: (context, state) => const CartPage(),
      ),

      // Agent profile (revamp) – use copy in revamp folder
      GoRoute(
        path: RoutePaths.agentProfileRevamp,
        name: RouteNames.agentProfileRevamp,
        builder: (context, state) {
          final args = state.extra as AgentProfileRevampArgs?;
          final agentId = args?.agentId ?? 'agent_demo';
          final agentName = args?.agentName ?? 'Demo Agent';
          return BlocProvider(
            create: (_) =>
                AgentProfileBloc(GetIt.instance<GetAgentProfileContent>())
                  ..add(LoadAgentProfile(agentId)),
            child: AgentProfileRevampPage(
              agent: {
                'id': agentId,
                'agentId': agentId,
                'name': agentName,
                'company': 'Company',
                'location': 'City, Country',
                'description': 'Mocked profile using copied old UI in revamp.',
                'products': <dynamic>[],
                'categories': <dynamic>[],
              },
            ),
          );
        },
      ),

      // Auth routes for login/register pages
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
