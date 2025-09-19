import 'dart:async';

import 'package:flutter/material.dart';

class BrandsMarquee extends StatefulWidget {
  const BrandsMarquee({super.key});

  @override
  State<BrandsMarquee> createState() => _BrandsMarqueeState();
}

class _BrandsMarqueeState extends State<BrandsMarquee> {
  late ScrollController _marqueeController;
  Timer? _marqueeTimer;

  // Brand logos for marquee
  final List<Map<String, String>> _brandLogos = [
    {'name': 'Apple', 'path': 'assets/logos/apple.png'},
    {'name': 'Costco', 'path': 'assets/logos/costco.png'},
    {'name': 'Dior', 'path': 'assets/logos/dior.png'},
    {'name': 'Louis Vuitton', 'path': 'assets/logos/lv.png'},
    {'name': 'Reliance', 'path': 'assets/logos/relaince.png'},
    {'name': 'Loro Piana', 'path': 'assets/logos/loro.png'},
    {'name': 'Tiffany', 'path': 'assets/logos/tiffany.png'},
  ];

  @override
  void initState() {
    super.initState();
    _marqueeController = ScrollController();
    _startMarqueeTimer();
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    _marqueeTimer?.cancel();
    super.dispose();
  }

  void _startMarqueeTimer() {
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted && _marqueeController.hasClients) {
        final maxScroll = _marqueeController.position.maxScrollExtent;
        final currentScroll = _marqueeController.offset;
        final singleSetWidth = maxScroll / 2; // Width of one complete set

        if (currentScroll >= singleSetWidth) {
          // Jump back to start of first set without animation for seamless loop
          _marqueeController.jumpTo(0);
        } else {
          // Continue scrolling smoothly
          _marqueeController.animateTo(
            currentScroll + 1,
            duration: const Duration(milliseconds: 30),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  void _onBrandTap(String brandName) {
    // Handle brand tap - could navigate to brand page or show brand details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped on $brandName'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        controller: _marqueeController,
        scrollDirection: Axis.horizontal,
        physics:
            const NeverScrollableScrollPhysics(), // Disable manual scrolling
        child: Row(
          children: [
            // First set of logos
            ..._brandLogos.map(
              (logo) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: GestureDetector(
                  onTap: () => _onBrandTap(logo['name']!),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        logo['path']!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.business,
                            color: Colors.grey[400],
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Second set of logos for seamless loop
            ..._brandLogos.map(
              (logo) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: GestureDetector(
                  onTap: () => _onBrandTap(logo['name']!),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        logo['path']!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.business,
                            color: Colors.grey[400],
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
