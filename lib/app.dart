// Main app file with clean architecture setup
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/firebase_init.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_paths.dart';
import 'di/core_module.dart';
import 'features/auth/di/auth_module.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/pda/di/pda_module.dart';
import 'features/profile/di/profile_module.dart';
import 'features/discover/di/discover_module.dart';
import 'shared/di/dependencies.dart';

final GetIt getIt = GetIt.instance;

Future<void> mainApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseInit.initialize();

  // Initialize dependency injection
  CoreModule.register();
  AuthModule.register();
  PdaModule.register();
  ProfileModule.init();
  DiscoverModule.init();
  setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => getIt<AuthBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Handle authentication state changes
          if (state is SignedOutState) {
            // Navigate to auth page when user signs out
            AppRouter.router.go(RoutePaths.mainAuth);
          } else if (state is AuthStateCheckedState) {
            // Handle authentication state check
            if (state.isAuthenticated && state.user != null) {
              // User is authenticated, check if they have a user card
              context.read<AuthBloc>().add(CheckUserCardEvent(state.user!.uid));
            }
          } else if (state is UserCardExistsState) {
            // Handle user card existence check result
            if (state.exists) {
              // User has a card, navigate to discover page
              AppRouter.router.go(RoutePaths.discover);
            } else {
              // User doesn't have a card, navigate to create first card page without args
              AppRouter.router.go(RoutePaths.createFirstCard);
            }
          } else if (state is UserCardCheckFailureState) {
            // Handle user card check failure - default to create first card without args
            AppRouter.router.go(RoutePaths.createFirstCard);
          }
        },
        child: _AppContent(),
      ),
    );
  }
}

class _AppContent extends StatefulWidget {
  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  @override
  void initState() {
    super.initState();
    // Check authentication state on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(CheckAuthStateEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hushh User App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA342FF),
          primary: const Color(0xFFA342FF),
          secondary: const Color(0xFFE54D60),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
