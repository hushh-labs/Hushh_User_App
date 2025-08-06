import 'package:flutter/material.dart';

class AllBrandsPage extends StatelessWidget {
  const AllBrandsPage({super.key});

  // Theme colors matching other pages
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);
  static const Color lightGreyBackground = Color(0xFFF9F9F9);

  Widget _buildBrandIconButton(
    BuildContext context,
    String title,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: () {
        // Handle brand selection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: $title'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, backgroundColor.withValues(alpha: 0.8)],
          ),
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
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor.withValues(alpha: 0.1),
                    iconColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Icon(
              Icons.arrow_forward_ios,
              color: iconColor.withValues(alpha: 0.6),
              size: 16,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryPurple, primaryPink],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'All Brands',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discover all our premium brands',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                // Apple
                _buildBrandIconButton(
                  context,
                  'Apple',
                  Icons.apple,
                  const Color(0xFFF5F5F5),
                  const Color(0xFF000000),
                ),
                // Costco
                _buildBrandIconButton(
                  context,
                  'Costco',
                  Icons.shopping_cart,
                  const Color(0xFFE8F5E8),
                  const Color(0xFF2E7D32),
                ),
                // Reliance
                _buildBrandIconButton(
                  context,
                  'Reliance',
                  Icons.store,
                  const Color(0xFFE3F2FD),
                  const Color(0xFF1976D2),
                ),
                // Louis Vuitton
                _buildBrandIconButton(
                  context,
                  'Louis Vuitton',
                  Icons.style,
                  const Color(0xFFF3E5F5),
                  const Color(0xFF9C27B0),
                ),
                // Christian Dior
                _buildBrandIconButton(
                  context,
                  'Christian Dior',
                  Icons.style,
                  const Color(0xFFE1F5FE),
                  const Color(0xFF0277BD),
                ),
                // Fendi
                _buildBrandIconButton(
                  context,
                  'Fendi',
                  Icons.style,
                  const Color(0xFFFFF8E1),
                  const Color(0xFFFF8F00),
                ),
                // Givenchy
                _buildBrandIconButton(
                  context,
                  'Givenchy',
                  Icons.style,
                  const Color(0xFFFCE4EC),
                  const Color(0xFFE91E63),
                ),
                // Celine
                _buildBrandIconButton(
                  context,
                  'Celine',
                  Icons.style,
                  const Color(0xFFE0F2F1),
                  const Color(0xFF00695C),
                ),
                // Kenzo
                _buildBrandIconButton(
                  context,
                  'Kenzo',
                  Icons.style,
                  const Color(0xFFE8EAF6),
                  const Color(0xFF3F51B5),
                ),
                // Loewe
                _buildBrandIconButton(
                  context,
                  'Loewe',
                  Icons.style,
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE65100),
                ),
                // Marc Jacobs
                _buildBrandIconButton(
                  context,
                  'Marc Jacobs',
                  Icons.style,
                  const Color(0xFFF1F8E9),
                  const Color(0xFF689F38),
                ),
                // Bulgari
                _buildBrandIconButton(
                  context,
                  'Bulgari',
                  Icons.diamond,
                  const Color(0xFFE8F5E8),
                  const Color(0xFF2E7D32),
                ),
                // Tiffany & Co.
                _buildBrandIconButton(
                  context,
                  'Tiffany & Co.',
                  Icons.diamond,
                  const Color(0xFFE0F2F1),
                  const Color(0xFF00695C),
                ),
                // Tag Heuer
                _buildBrandIconButton(
                  context,
                  'Tag Heuer',
                  Icons.watch,
                  const Color(0xFFE3F2FD),
                  const Color(0xFF1976D2),
                ),
                // Hublot
                _buildBrandIconButton(
                  context,
                  'Hublot',
                  Icons.watch,
                  const Color(0xFFF5F5F5),
                  const Color(0xFF424242),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
