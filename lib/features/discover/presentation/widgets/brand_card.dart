import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/brand_model.dart';

class BrandCard extends StatelessWidget {
  final BrandModel brand;
  final VoidCallback? onTap;

  const BrandCard({super.key, required this.brand, this.onTap});

  Color _parseHexColor(String hexCode) {
    try {
      // Remove # if present
      String hex = hexCode.replaceAll('#', '');

      // Handle different hex formats
      if (hex.length == 3) {
        hex = hex.split('').map((c) => c + c).join();
      }

      // Add alpha if not present
      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      // Return default color if parsing fails
      return const Color(0xFF000000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _parseHexColor(brand.hexCode);
    final iconColor = _getContrastColor(backgroundColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: brand.iconLink.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: brand.iconLink,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Icon(Icons.business, color: iconColor, size: 48),
                errorWidget: (context, url, error) =>
                    Icon(Icons.business, color: iconColor, size: 48),
              )
            : Icon(Icons.business, color: iconColor, size: 48),
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
