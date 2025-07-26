// Main app file with clean architecture setup
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/config/firebase_init.dart';
import 'core/routing/app_router.dart';


final GetIt getIt = GetIt.instance;

Future<void> mainApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseInit.initialize();

  // Initialize dependency injection
 // AuthModule.init(getIt);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
     //   BlocProvider<AuthBloc>(create: (context) => getIt<AuthBloc>()),
      ],
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
