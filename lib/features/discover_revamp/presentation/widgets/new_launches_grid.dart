import 'package:flutter/material.dart';

class NewLaunchesGrid extends StatelessWidget {
  const NewLaunchesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _LaunchItem('Apple', 'assets/logos/apple.png', Color(0xFFE6F0FF)),
      _LaunchItem('Dior', 'assets/logos/dior.png', Color(0xFFEFE3FF)),
      _LaunchItem('LV', 'assets/logos/lv.png', Color(0xFFFFF4CC)),
      _LaunchItem('Tiffany', 'assets/logos/tiffany.png', Color(0xFFDDF5F8)),
      _LaunchItem('Loro', 'assets/logos/loro.png', Color(0xFFE9F5E9)),
      _LaunchItem('Costco', 'assets/logos/costco.png', Color(0xFFFFE3E6)),
      _LaunchItem('Reliance', 'assets/logos/relaince.png', Color(0xFFF1F1F1)),
      _LaunchItem('More', 'assets/logos/tiffany.png', Color(0xFFEDEDED)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: item.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(item.asset, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LaunchItem {
  final String title;
  final String asset;
  final Color bg;
  const _LaunchItem(this.title, this.asset, this.bg);
}
