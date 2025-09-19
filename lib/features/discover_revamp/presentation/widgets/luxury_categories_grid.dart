import 'package:flutter/material.dart';

class LuxuryCategoriesGrid extends StatelessWidget {
  const LuxuryCategoriesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alexandra, Want to level up your game?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.9, // h-36 like card ratio
            children: const [
              _CategoryCard(
                title: 'Fashion',
                imageUrl:
                    'https://images.unsplash.com/photo-1583791031288-d48c4326d5da?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxidXJiZXJyeSUyMGx1eHVyeSUyMGJhZyUyMGZhc2hpb258ZW58MXx8fHwxNzU4MTM0ODM1fDA&ixlib=rb-4.1.0&q=80&w=1080',
              ),
              _CategoryCard(
                title: 'Jewelry',
                imageUrl:
                    'https://images.unsplash.com/photo-1709101051601-5cee6a1ff5fe?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsdXh1cnklMjB3YXRjaCUyMHJvbGV4JTIwamV3ZWxyeXxlbnwxfHx8fDE3NTgxMzQ4Mzl8MA&ixlib=rb-4.1.0&q=80&w=1080',
              ),
              _CategoryCard(
                title: 'Watches',
                imageUrl:
                    'https://images.unsplash.com/photo-1730757679771-b53e798846cf?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsdXh1cnklMjB3YXRjaGVzJTIwY29sbGVjdGlvbnxlbnwxfHx8fDE3NTgwNzU4MjZ8MA&ixlib=rb-4.1.0&q=80&w=1080',
              ),
              _CategoryCard(
                title: 'Lifestyle',
                imageUrl:
                    'https://images.unsplash.com/photo-1638885930125-85350348d266?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsdXh1cnklMjBsaWZlc3R5bGUlMjBpbnRlcmlvciUyMG1vZGVybnxlbnwxfHx8fDE3NTgxMzQ4NDd8MA&ixlib=rb-4.1.0&q=80&w=1080',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  const _CategoryCard({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(imageUrl, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x33000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
