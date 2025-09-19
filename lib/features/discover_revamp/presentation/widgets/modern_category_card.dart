import 'package:flutter/material.dart';

class ModernCategoryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? assetImagePath;
  final IconData? fallbackIcon;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final List<Color>? gradientColors;
  final bool showTitleOverlay;

  const ModernCategoryCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.assetImagePath,
    this.fallbackIcon,
    this.onTap,
    this.width,
    this.height = 120,
    this.gradientColors,
    this.showTitleOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image or Gradient
              _buildBackground(),

              if (showTitleOverlay)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (assetImagePath != null && assetImagePath!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [Color(0xFFFFD6A5), Color(0xFFFFAD60)],
              ),
            ),
          ),
          Image.asset(
            assetImagePath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackBackground(),
          ),
        ],
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackBackground(),
      );
    }
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    final colors =
        gradientColors ??
        [
          const Color(0xFFFFD6A5), // soft orange
          const Color(0xFFFFAD60), // deeper orange
        ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: fallbackIcon != null
          ? Center(
              child: Icon(
                fallbackIcon,
                size: 40,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            )
          : null,
    );
  }
}
