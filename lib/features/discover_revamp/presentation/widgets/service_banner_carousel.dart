import 'dart:async';

import 'package:flutter/material.dart';
import '../pages/product_revamp_page.dart';

class ServiceBannerCarousel extends StatefulWidget {
  const ServiceBannerCarousel({super.key});

  @override
  State<ServiceBannerCarousel> createState() => _ServiceBannerCarouselState();
}

class _ServiceBannerCarouselState extends State<ServiceBannerCarousel> {
  late final Timer _timer;
  int _currentIndex = 0;

  final List<_BannerItem> _banners = [
    _BannerItem(
      title: 'DIOR',
      subtitle: 'Haute Couture',
      description:
          'Experience the pinnacle of French luxury with exclusive Dior collections',
      imageUrl:
          'https://images.unsplash.com/photo-1601835884504-8a4c45324cc1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaW9yJTIwbHV4dXJ5JTIwZmFzaGlvbnxlbnwxfHx8fDE3NTgxMjc2NDF8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      badge: 'COUTURE',
      tagline: 'Artistry meets elegance',
      gradientColors: const [
        Color(0xCC0F172A), // ~80%
        Color(0x80000000), // ~50%
        Color(0x8F000000), // ~56%
      ],
      brandColor: const Color(0xFFD1D5DB), // gray-200
      icon: Icons.change_history, // triangle-like
    ),
    _BannerItem(
      title: 'FENDI',
      subtitle: 'Italian Craftsmanship',
      description:
          'Discover the finest Italian leather goods and timeless luxury accessories',
      imageUrl:
          'https://images.unsplash.com/photo-1574271143443-3a7b2e7a36bd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmZW5kaSUyMGx1eHVyeSUyMGhhbmRiYWdzfGVufDF8fHx8MTc1ODEzMjMwN3ww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      badge: 'ARTISAN',
      tagline: 'Masterful Italian heritage',
      gradientColors: const [
        Color(0xCC6A3A0B), // ~80%
        Color(0x80000000), // ~50%
        Color(0x8FC2410C), // ~56%
      ],
      brandColor: Color(0xFFFDE68A), // amber-200
      icon: Icons.favorite_outline,
    ),
    _BannerItem(
      title: 'LOUIS VUITTON',
      subtitle: 'Maison Heritage',
      description:
          'Step into a world of unparalleled luxury with Louis Vuitton\'s iconic designs',
      imageUrl:
          'https://images.unsplash.com/photo-1755514838747-adfd34197d39?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsb3VpcyUyMHZ1aXR0b24lMjBsdXh1cnl8ZW58MXx8fHwxNzU4MTI3NjIxfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      badge: 'ICONIC',
      tagline: 'Legend of luxury travel',
      gradientColors: const [
        Color(0xCCB45309),
        Color(0x80000000),
        Color(0x8FB45309),
      ],
      brandColor: Color(0xFFFDE68A),
      icon: Icons.star_outline,
    ),
    _BannerItem(
      title: 'BULGARI',
      subtitle: 'Roman Jeweler',
      description:
          'Indulge in the magnificent world of Bulgari\'s exceptional jewelry collections',
      imageUrl:
          'https://images.unsplash.com/photo-1667013829921-b1c1719a0cfa?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxidWxnYXJpJTIwamV3ZWxyeSUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzMTJ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      badge: 'JEWELRY',
      tagline: 'Eternal Roman magnificence',
      gradientColors: const [
        Color(0xCC511F8B),
        Color(0x80000000),
        Color(0x8F7316D1),
      ],
      brandColor: Color(0xFFE9D5FF), // purple-200
      icon: Icons.hub_outlined,
    ),
    _BannerItem(
      title: 'TIFFANY & CO.',
      subtitle: 'American Luxury',
      description:
          "Celebrate life's special moments with Tiffany's legendary jewelry and gifts",
      imageUrl:
          'https://images.unsplash.com/photo-1585248460091-ee6840661547?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0aWZmYW55JTIwamV3ZWxyeSUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzMTV8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      badge: 'LEGENDARY',
      tagline: 'A diamond is forever',
      gradientColors: const [
        Color(0xCC0F766E),
        Color(0x80000000),
        Color(0x8F0E7490),
      ],
      brandColor: Color(0xFF99F6E4), // teal-200
      icon: Icons.timelapse,
    ),
    _BannerItem(
      title: 'CARTIER',
      subtitle: 'King of Jewelers',
      description:
          'Discover Cartier\'s prestigious watches and jewelry, crafted for royalty',
      imageUrl:
          'https://images.unsplash.com/photo-1581063683670-6df2247f1d8e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXJ0aWVyJTIwd2F0Y2hlcyUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzMTh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      badge: 'ROYAL',
      tagline: 'Jeweler of kings & king of jewelers',
      gradientColors: const [
        Color(0xCC900F0F),
        Color(0x80000000),
        Color(0x8FBE123C),
      ],
      brandColor: Color(0xFFFECACA), // red-200
      icon: Icons.history_toggle_off,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final next = (_currentIndex + 1) % _banners.length;
      setState(() {
        _currentIndex = next;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            // Fade carousel
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: ClipRRect(
                  key: ValueKey<int>(_currentIndex),
                  borderRadius: BorderRadius.circular(12),
                  child: _BannerSlide(item: _banners[_currentIndex]),
                ),
              ),
            ),
            // Indicators
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) {
                  final isActive = i == _currentIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final _BannerItem item;

  const _BannerSlide({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(item.imageUrl, fit: BoxFit.cover),
          // horizontal gradient overlay (3-stop)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: item.gradientColors,
                ),
              ),
            ),
          ),
          // bottom fade
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x4D000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.badge,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 10,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exclusively on Hushh',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              item.tagline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductRevampPage(
                                productName: item.subtitle,
                                brand: item.title,
                                subtitle: item.tagline,
                                description: item.description,
                                longDescription:
                                    "Experience luxury like never before with this exclusive collection. Crafted with the finest materials and attention to detail, this piece represents the pinnacle of luxury fashion.",
                                imageUrls: [
                                  item.imageUrl,
                                  // demo alternates
                                  'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?auto=format&fit=crop&w=1080&q=80',
                                  'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?auto=format&fit=crop&w=1080&q=80',
                                  'https://images.unsplash.com/photo-1520975916090-3105956dac38?auto=format&fit=crop&w=1080&q=80',
                                ],
                                price: 345000.0,
                                highlights: const [
                                  "Limited Edition",
                                  "Handcrafted",
                                  "Premium Materials",
                                ],
                                rating: 4.8,
                                reviewCount: 127,
                                material: "Premium Leather",
                                dimensions: "30cm x 20cm x 10cm",
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D1D1F),
                          minimumSize: const Size(40, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text(
                          'Explore',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Decorative dots
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 28,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 52,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerItem {
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final String badge;
  final String tagline;
  final List<Color> gradientColors;
  final Color brandColor;
  final IconData icon;

  const _BannerItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.badge,
    required this.tagline,
    required this.gradientColors,
    required this.brandColor,
    required this.icon,
  });
}
