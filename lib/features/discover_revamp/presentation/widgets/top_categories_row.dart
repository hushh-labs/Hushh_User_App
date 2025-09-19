import 'package:flutter/material.dart';

class TopCategoriesRow extends StatelessWidget {
  const TopCategoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _CategoryItem('Fashion', 'assets/categories/fashion.png'),
      _CategoryItem('Technology', 'assets/categories/tech.png'),
      _CategoryItem('Watches', 'assets/categories/watch.png'),
      _CategoryItem('More', 'assets/categories/general.png'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0, // perfect square
        ),
        itemBuilder: (context, index) {
          final it = items[index];
          return _CategoryCard(title: it.title, assetPath: it.assetPath);
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String assetPath;

  const _CategoryCard({required this.title, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(assetPath, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xB3000000),
                  Color(0x33000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final String assetPath;
  const _CategoryItem(this.title, this.assetPath);
}
