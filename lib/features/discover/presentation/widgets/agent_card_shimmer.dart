import 'package:flutter/material.dart';

/// Shimmer loading widget for agent cards in the Discover page
class AgentCardShimmer extends StatefulWidget {
  const AgentCardShimmer({super.key});

  @override
  State<AgentCardShimmer> createState() => _AgentCardShimmerState();
}

class _AgentCardShimmerState extends State<AgentCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildShimmerContainer({
    required double height,
    double? width,
    double borderRadius = 8.0,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFF0F0F0),
                Color(0xFFE0E0E0),
                Color(0xFFF0F0F0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double radius = 16;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top image area with shimmer
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
            ),
            child: Stack(
              children: [
                // Background shimmer
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xFFFAF9F6)),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
                // Agent label shimmer
                Positioned(
                  right: 8,
                  top: 8,
                  child: _buildShimmerContainer(
                    height: 20,
                    width: 50,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ),

          // Details section with shimmer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Agent name shimmer
                  _buildShimmerContainer(height: 18, width: double.infinity),
                  const SizedBox(height: 1),
                  // Brand name shimmer
                  _buildShimmerContainer(height: 14, width: 80),
                  const SizedBox(height: 2),
                  // Info text shimmer
                  _buildShimmerContainer(height: 12, width: 60),
                  const Spacer(),
                  // Button shimmer
                  Row(
                    children: [
                      const Spacer(),
                      _buildShimmerContainer(
                        height: 24,
                        width: 24,
                        borderRadius: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
