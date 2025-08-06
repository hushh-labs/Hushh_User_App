import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

import 'order_confirmation_page.dart';
import '../bloc/cart_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderSuccessPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final String agentName;
  final String brandName;
  final double totalPrice;
  final String agentPhone;
  final String customerName;
  final CartBloc cartBloc;

  const OrderSuccessPage({
    super.key,
    required this.cartItems,
    required this.agentName,
    required this.brandName,
    required this.totalPrice,
    required this.agentPhone,
    required this.customerName,
    required this.cartBloc,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _showSuccessText = false;
  bool _showSubtitle = false;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animation sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start the main animation
    _animationController.forward();

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        _showSuccessText = true;
      });
      _fadeController.forward();
    }

    // Show subtitle after success text
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showSubtitle = true;
      });
    }

    // Show progress indicator
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showProgress = true;
      });
      _scaleController.forward();
    }

    // Navigate to confirmation page after 5 seconds total
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: widget.cartBloc,
            child: OrderConfirmationPage(
              cartItems: widget.cartItems,
              agentName: widget.agentName,
              brandName: widget.brandName,
              totalPrice: widget.totalPrice,
              agentPhone: widget.agentPhone,
              customerName: widget.customerName,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Animation Container
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(140),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.9 + (_animationController.value * 0.1),
                        child: Lottie.asset(
                          'assets/Success.json',
                          controller: _animationController,
                          onLoaded: (composition) {
                            _animationController.duration =
                                composition.duration;
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Success Text
              AnimatedOpacity(
                opacity: _showSuccessText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: const Text(
                        'Order Successful!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              AnimatedOpacity(
                opacity: _showSubtitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: const Text(
                  'Your order has been placed successfully',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // Progress Indicator
              AnimatedOpacity(
                opacity: _showProgress ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Preparing your receipt...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
