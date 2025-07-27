import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_paths.dart';

class CardCreatedSuccessPage extends StatefulWidget {
  const CardCreatedSuccessPage({super.key});

  @override
  State<CardCreatedSuccessPage> createState() => _CardCreatedSuccessPageState();
}

class _CardCreatedSuccessPageState extends State<CardCreatedSuccessPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to discover page after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        // Use GoRouter to navigate to discover page
        context.go(RoutePaths.discover);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0XFFA342FF), Color(0XFFE54D60)],
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 30),
              const Text(
                'Card Created Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your digital card has been created and is ready to use.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0XFFA342FF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
