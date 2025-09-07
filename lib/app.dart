// Main app file with clean architecture setup
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/config/firebase_init.dart';
import 'core/config/supabase_init.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_paths.dart';
import 'di/core_module.dart';
import 'features/auth/di/auth_module.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/pda/di/pda_module.dart';
import 'features/pda/di/gmail_module.dart';
import 'features/pda/di/linkedin_module.dart';
import 'features/pda/di/google_meet_module.dart';
import 'features/profile/di/profile_module.dart';
import 'features/discover/di/discover_module.dart';
import 'features/notifications/di/notification_module.dart';
import 'features/chat/di/chat_module.dart';
import 'features/vault/di/vault_module.dart';
import 'shared/di/dependencies.dart';
import 'shared/utils/app_local_storage.dart';
import 'features/notifications/data/services/notification_service.dart';
import 'features/discover/presentation/bloc/cart_bloc.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'shared/services/gmail_connector_service.dart';
import 'features/pda/data/data_sources/pda_vertex_ai_data_source_impl.dart';
import 'features/pda/data/services/linkedin_context_prewarm_service.dart';
import 'features/pda/data/services/gmail_context_prewarm_service.dart';
import 'features/pda/data/services/google_meet_context_prewarm_service.dart';
import 'features/vault/data/services/vault_startup_prewarm_service.dart';
import 'features/vault/data/services/local_file_cache_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> mainApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseInit.initialize();

  // Initialize Supabase
  await SupabaseInit.initialize();

  // Initialize guest mode state
  await AppLocalStorage.initializeGuestMode();

  // Initialize dependency injection
  CoreModule.register();
  AuthModule.register();
  PdaModule.register();
  GmailModule.register();
  LinkedInModule.register();
  GoogleMeetModule.register();
  ProfileModule.init();
  DiscoverModule.init();
  NotificationModule.register();
  ChatModule.init();
  VaultModule.init(getIt);
  setupDependencies();

  // Initialize local notifications/channels early
  try {
    // NotificationRepository is registered in NotificationModule
    final notificationRepo = getIt<NotificationRepository>();
    await NotificationService().initialize(notificationRepo);
  } catch (_) {}

  // Initialize local file cache service
  try {
    final cacheService = getIt<LocalFileCacheService>();
    await cacheService.initialize();
    debugPrint('💾 [APP] Local file cache initialized successfully');
  } catch (e) {
    debugPrint('❌ [APP] Error initializing local file cache: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => getIt<AuthBloc>()),
        // Provide CartBloc globally so cart is always available across pages
        BlocProvider<CartBloc>.value(value: getIt<CartBloc>()),
      ],
      child: _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  final GmailConnectorService _gmailService = GmailConnectorService();
  final LinkedInContextPrewarmService _linkedInPrewarmService =
      LinkedInContextPrewarmService();
  final GmailContextPrewarmService _gmailPrewarmService =
      GmailContextPrewarmService();
  final GoogleMeetContextPrewarmService _googleMeetPrewarmService =
      GoogleMeetContextPrewarmService();
  late final VaultStartupPrewarmService _vaultPrewarmService;
  PdaVertexAiDataSourceImpl? _pdaDataSource;

  @override
  void initState() {
    super.initState();
    // Initialize vault prewarm service
    _vaultPrewarmService = getIt<VaultStartupPrewarmService>();

    // Check authentication state on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(CheckAuthStateEvent());
    });
  }

  @override
  void dispose() {
    _stopEmailMonitoring();
    super.dispose();
  }

  /// Start email monitoring for real-time updates
  Future<void> _startEmailMonitoring() async {
    try {
      debugPrint('📧 [APP] Starting Gmail email monitoring...');

      // Start Gmail connector monitoring
      await _gmailService.startEmailMonitoring();

      // Start PDA email monitoring
      try {
        _pdaDataSource = getIt<PdaVertexAiDataSourceImpl>();
        await _pdaDataSource?.startEmailMonitoring();
      } catch (e) {
        debugPrint('📧 [APP] PDA service not available: $e');
      }

      debugPrint('📧 [APP] Email monitoring started successfully');
    } catch (e) {
      debugPrint('❌ [APP] Error starting email monitoring: $e');
    }
  }

  /// Stop email monitoring
  void _stopEmailMonitoring() {
    try {
      debugPrint('📧 [APP] Stopping Gmail email monitoring...');

      _gmailService.stopEmailMonitoring();
      _pdaDataSource?.stopEmailMonitoring();
      _pdaDataSource = null;

      debugPrint('📧 [APP] Email monitoring stopped');
    } catch (e) {
      debugPrint('❌ [APP] Error stopping email monitoring: $e');
    }
  }

  /// Prewarm PDA with user context, email data, LinkedIn context, and vault documents
  Future<void> _prewarmPDA(String userId) async {
    try {
      debugPrint('🧠 [APP] Starting PDA prewarming for user: $userId');

      // Clear local file cache and Firestore context on app restart to ensure fresh data
      try {
        final cacheService = getIt<LocalFileCacheService>();
        await cacheService.clearUserCache(userId);
        debugPrint('🗑️ [APP] Cleared local file cache for fresh restart');

        // Also clear the Firestore vault context to force rebuild
        await FirebaseFirestore.instance
            .collection('HushUsers')
            .doc(userId)
            .collection('pda_context')
            .doc('vault')
            .delete();
        debugPrint(
          '🗑️ [APP] Cleared Firestore vault context for fresh restart',
        );
      } catch (e) {
        debugPrint('⚠️ [APP] Error clearing cache: $e');
      }

      // Get PDA data source and prewarm context
      _pdaDataSource = getIt<PdaVertexAiDataSourceImpl>();
      await _pdaDataSource?.prewarmUserContext(userId);

      // Also pre-warm Gmail, LinkedIn, Google Meet, and Vault context in parallel for faster loading
      _gmailPrewarmService.prewarmGmailContext();
      _linkedInPrewarmService.prewarmLinkedInContext();
      _googleMeetPrewarmService.prewarmGoogleMeetContext();
      _vaultPrewarmService.prewarmVaultOnStartup();

      debugPrint('🧠 [APP] PDA prewarming completed');
    } catch (e) {
      debugPrint('❌ [APP] Error prewarming PDA: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle authentication state changes
        if (state is SignedOutState) {
          // Stop email monitoring when user signs out
          _stopEmailMonitoring();
          // Navigate to auth page when user signs out
          AppRouter.router.go(RoutePaths.mainAuth);
        } else if (state is AuthStateCheckedState) {
          // Handle authentication state check
          if (state.isAuthenticated && state.user != null) {
            // User is authenticated, start email monitoring and check profile completion
            _startEmailMonitoring();
            _prewarmPDA(state.user!.uid);
            context.read<AuthBloc>().add(
              CheckUserProfileCompletionEvent(state.user!.uid),
            );
          }
        } else if (state is UserProfileCompletedState) {
          // Handle user profile completion check result
          if (state.isCompleted) {
            // User has completed profile, navigate to discover page
            AppRouter.router.go(RoutePaths.discover);
          } else {
            // User hasn't completed profile, navigate to create first card page
            AppRouter.router.go(RoutePaths.createFirstCard);
          }
        } else if (state is UserProfileCheckFailureState) {
          // Handle user profile check failure - default to create first card
          AppRouter.router.go(RoutePaths.createFirstCard);
        }
      },
      child: MaterialApp.router(
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
      ),
    );
  }
}
