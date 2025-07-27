import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../shared/core/utils/toast_manager.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(SignOutEvent());
            },
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is SignedOutState) {
            // Navigate back to auth page
            context.go(RoutePaths.mainAuth);
          } else if (state is SignOutFailureState) {
            ToastManager(
              Toast(
                title: 'Sign Out Failed',
                description: state.message,
                type: ToastType.error,
                duration: const Duration(seconds: 4),
              ),
            ).show(context);
          }
        },
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore, size: 100, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Discover Page',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your card has been created successfully!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
