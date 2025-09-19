import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartnerAgentsPage extends StatelessWidget {
  const PartnerAgentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Partner Brands',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Luxury Brand Partners',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Discover our exclusive partnerships with the world\'s most prestigious luxury brands',
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),

            // LVMH Brands Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _lvmhBrands.length,
              itemBuilder: (context, index) {
                final brand = _lvmhBrands[index];
                return _LuxuryBrandButton(
                  brand: brand,
                  onTap: () {
                    // Handle brand tap
                    _showBrandDetails(context, brand);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBrandDetails(BuildContext context, LVMHBrand brand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BrandDetailsModal(brand: brand),
    );
  }
}

class _LuxuryBrandButton extends StatelessWidget {
  final LVMHBrand brand;
  final VoidCallback onTap;

  const _LuxuryBrandButton({required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  brand.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: brand.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Name
                      Text(
                        brand.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Brand Description
                      Text(
                        brand.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
}

class _BrandDetailsModal extends StatelessWidget {
  final LVMHBrand brand;

  const _BrandDetailsModal({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(brand.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              brand.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              brand.category,
                              style: TextStyle(
                                fontSize: 14,
                                color: brand.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    brand.fullDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1D1D1F),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Features
                  const Text(
                    'Key Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...brand.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.black54,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Handle contact action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF1D1D1F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        'Contact Agent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

// Data Models
class LVMHBrand {
  final String name;
  final String category;
  final String description;
  final String fullDescription;
  final String imageUrl;
  final Color accentColor;
  final List<Color> gradient;
  final List<String> features;

  LVMHBrand({
    required this.name,
    required this.category,
    required this.description,
    required this.fullDescription,
    required this.imageUrl,
    required this.accentColor,
    required this.gradient,
    required this.features,
  });
}

// LVMH Brands Data
final List<LVMHBrand> _lvmhBrands = [
  LVMHBrand(
    name: 'Louis Vuitton',
    category: 'FASHION',
    description: 'French luxury fashion house',
    fullDescription:
        'Louis Vuitton is a French luxury fashion house and company founded in 1854 by Louis Vuitton. The label\'s LV monogram appears on most of its products, ranging from luxury trunks and leather goods to ready-to-wear, shoes, watches, jewelry, accessories, sunglasses, and books.',
    imageUrl:
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsb3VpcyUyMHZ1aXR0b24lMjBsdXh1cnl8ZW58MXx8fHwxNzU4MTI3NjIxfDA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Luxury leather goods and accessories',
      'Ready-to-wear collections',
      'Exclusive trunk customization',
      'Worldwide flagship stores',
    ],
  ),
  LVMHBrand(
    name: 'Dior',
    category: 'COUTURE',
    description: 'French luxury goods company',
    fullDescription:
        'Christian Dior SE, commonly known as Dior, is a French luxury goods company controlled and chaired by French businessman Bernard Arnault, who also heads LVMH. Dior holds 42.36% of LVMH and 59.01% of the voting rights within LVMH.',
    imageUrl:
        'https://images.unsplash.com/photo-1601835884504-8a4c45324cc1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaW9yJTIwbHV4dXJ5JTIwZmFzaGlvbnxlbnwxfHx8fDE3NTgxMjc2NDF8MA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Haute couture collections',
      'Luxury ready-to-wear',
      'Perfumes and cosmetics',
      'Jewelry and watches',
    ],
  ),
  LVMHBrand(
    name: 'Fendi',
    category: 'LEATHER',
    description: 'Italian luxury fashion house',
    fullDescription:
        'Fendi is an Italian luxury fashion house producing fur, ready-to-wear, leather goods, shoes, fragrances, eyewear, timepieces and accessories. Founded in Rome in 1925, Fendi is known for its fur and leather goods.',
    imageUrl:
        'https://images.unsplash.com/photo-1574271143443-3a7b2e7a36bd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmZW5kaSUyMGx1eHVyeSUyMGhhbmRiYWdzfGVufDF8fHx8MTc1ODEzMjMwN3ww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Iconic Baguette handbags',
      'Luxury fur collections',
      'Italian craftsmanship',
      'Contemporary ready-to-wear',
    ],
  ),
  LVMHBrand(
    name: 'Bulgari',
    category: 'JEWELRY',
    description: 'Italian luxury jewelry brand',
    fullDescription:
        'Bulgari is an Italian luxury brand known for its jewelry, watches, fragrances, accessories, leather goods, and hotels. Founded in 1884, Bulgari is renowned for its colorful gemstones and bold designs.',
    imageUrl:
        'https://images.unsplash.com/photo-1667013829921-b1c1719a0cfa?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxidWxnYXJpJTIwamV3ZWxyeSUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzMTJ8MA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'High-end jewelry collections',
      'Luxury timepieces',
      'Exclusive gemstone sourcing',
      'Roman heritage and design',
    ],
  ),
  LVMHBrand(
    name: 'Tiffany & Co.',
    category: 'JEWELRY',
    description: 'American luxury jewelry retailer',
    fullDescription:
        'Tiffany & Co. is an American luxury jewelry and specialty retailer, headquartered on 5th Avenue in Manhattan. It sells jewelry, sterling silver, china, crystal, stationery, fragrances, water bottles, watches, personal accessories, and leather goods.',
    imageUrl:
        'https://images.unsplash.com/photo-1585248460091-ee6840661547?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0aWZmYW55JTIwamV3ZWxyeSUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzMTV8MA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Iconic Tiffany Blue boxes',
      'Diamond engagement rings',
      'Luxury timepieces',
      'Signature jewelry collections',
    ],
  ),
  LVMHBrand(
    name: 'Cartier',
    category: 'JEWELRY',
    description: 'French luxury jewelry manufacturer',
    fullDescription:
        'Cartier is a French luxury goods conglomerate which designs, manufactures, distributes, and sells jewelry and watches. Founded by Louis-François Cartier in Paris in 1847, the company remained under family control until 1964.',
    imageUrl:
        'https://images.unsplash.com/photo-1581063683670-6df2247f1d8e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXJ0aWVyJTIwd2F0Y2hlcyUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzMTh8MA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Royal jewelry collections',
      'Luxury timepieces',
      'High jewelry pieces',
      'Jeweler of kings heritage',
    ],
  ),
  LVMHBrand(
    name: 'Givenchy',
    category: 'FASHION',
    description: 'French luxury fashion house',
    fullDescription:
        'Givenchy is a French luxury fashion and perfume house. It hosts the brand of haute couture clothing, accessories, perfumes and cosmetics. The house of Givenchy was founded in 1952 by designer Hubert de Givenchy.',
    imageUrl:
        'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxnaXZlbmNoeSUyMGx1eHVyeSUyMGZhc2hpb258ZW58MXx8fHwxNzU4MTMyMzIxfDA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Haute couture collections',
      'Luxury ready-to-wear',
      'Signature perfumes',
      'Accessories and leather goods',
    ],
  ),
  LVMHBrand(
    name: 'Celine',
    category: 'FASHION',
    description: 'French luxury fashion house',
    fullDescription:
        'Celine is a French luxury fashion house founded in 1945 by Céline Vipiana. It specializes in leather goods, ready-to-wear, shoes, and accessories. The brand is known for its minimalist aesthetic and high-quality craftsmanship.',
    imageUrl:
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjZWxpbmUlMjBsdXh1cnklMjBmYXNoaW9ufGVufDF8fHx8MTc1ODEzMjMyNHww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Minimalist luxury design',
      'Premium leather goods',
      'Contemporary ready-to-wear',
      'Sophisticated accessories',
    ],
  ),
  LVMHBrand(
    name: 'Loewe',
    category: 'LEATHER',
    description: 'Spanish luxury fashion house',
    fullDescription:
        'Loewe is a Spanish luxury fashion house specializing in leather goods, clothing, perfumes and other fashion accessories. Founded in 1846, it is one of the world\'s oldest luxury fashion houses.',
    imageUrl:
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsb2V3ZSUyMGx1eHVyeSUyMGZhc2hpb258ZW58MXx8fHx8MTc1ODEzMjMyN3ww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Artisanal leather goods',
      'Contemporary Spanish design',
      'Luxury ready-to-wear',
      'Unique craftsmanship',
    ],
  ),
  LVMHBrand(
    name: 'Kenzo',
    category: 'FASHION',
    description: 'French luxury fashion house',
    fullDescription:
        'Kenzo is a French luxury fashion house founded in 1970 by Japanese designer Kenzo Takada. The brand is known for its bold prints, vibrant colors, and fusion of Japanese and French aesthetics.',
    imageUrl:
        'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxrZW56byUyMGx1eHVyeSUyMGZhc2hpb258ZW58MXx8fHx8MTc1ODEzMjMzMHww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Bold and vibrant designs',
      'Japanese-French fusion',
      'Contemporary ready-to-wear',
      'Signature tiger motifs',
    ],
  ),
  LVMHBrand(
    name: 'Marc Jacobs',
    category: 'FASHION',
    description: 'American luxury fashion brand',
    fullDescription:
        'Marc Jacobs is an American luxury fashion brand founded by designer Marc Jacobs. The brand is known for its contemporary, edgy designs and has become a favorite among fashion-forward consumers.',
    imageUrl:
        'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYXJjJTIwamFjb2JzJTIwbHV4dXJ5JTIwZmFzaGlvbnxlbnwxfHx8fDE3NTgxMzIzMzN8MA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Contemporary luxury design',
      'Edgy and innovative styles',
      'Accessories and leather goods',
      'Fashion-forward collections',
    ],
  ),
  LVMHBrand(
    name: 'Fenty',
    category: 'BEAUTY',
    description: 'Inclusive luxury beauty brand',
    fullDescription:
        'Fenty Beauty is a cosmetics brand founded by Rihanna in 2017. The brand is known for its inclusive range of foundation shades and innovative beauty products that cater to all skin tones.',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmZW50eSUyMGJlYXV0eSUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzMzZ8MA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Inclusive foundation shades',
      'Innovative beauty products',
      'Diverse representation',
      'High-quality formulations',
    ],
  ),
  LVMHBrand(
    name: 'Sephora',
    category: 'BEAUTY',
    description: 'French multinational beauty retailer',
    fullDescription:
        'Sephora is a French multinational chain of personal care and beauty stores. Founded in 1970, it offers a wide range of cosmetics, skincare, fragrance, nail color, beauty tools, and haircare products.',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzZXBob3JhJTIwYmVhdXR5JTIwbHV4dXJ5fGVufDF8fHx8MTc1ODEzMjMzOXww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Extensive beauty selection',
      'Expert beauty consultations',
      'Exclusive brand partnerships',
      'Innovative beauty technology',
    ],
  ),
  LVMHBrand(
    name: 'Make Up For Ever',
    category: 'BEAUTY',
    description: 'Professional makeup brand',
    fullDescription:
        'Make Up For Ever is a French professional makeup brand founded in 1984. The brand is known for its high-performance, professional-grade makeup products used by makeup artists worldwide.',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYWtldXAlMjBmb3IlMjBldmVyJTIwYmVhdXR5fGVufDF8fHx8MTc1ODEzMjM0Mnww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Professional-grade makeup',
      'Artist-approved formulas',
      'Extensive color ranges',
      'Long-lasting performance',
    ],
  ),
  LVMHBrand(
    name: 'Benefit Cosmetics',
    category: 'BEAUTY',
    description: 'American cosmetics brand',
    fullDescription:
        'Benefit Cosmetics is an American cosmetics brand founded in 1976. The brand is known for its fun, quirky packaging and effective beauty products, particularly in the areas of brows, mascara, and skincare.',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZW5lZml0JTIwY29zbWV0aWNzJTIwYmVhdXR5fGVufDF8fHx8MTc1ODEzMjM0NXww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Fun and quirky designs',
      'Effective beauty solutions',
      'Brow and mascara expertise',
      'Skincare innovations',
    ],
  ),
  LVMHBrand(
    name: 'Fresh',
    category: 'BEAUTY',
    description: 'Luxury skincare brand',
    fullDescription:
        'Fresh is a luxury skincare brand founded in 1991. The brand is known for its natural, effective skincare products that combine traditional ingredients with modern technology.',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmcmVzaCUyMHNraW5jYXJlJTIwbHV4dXJ5fGVufDF8fHx8MTc1ODEzMjM0OHww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Natural skincare ingredients',
      'Traditional meets modern',
      'Luxury formulations',
      'Effective results',
    ],
  ),
  LVMHBrand(
    name: 'Kiehl\'s',
    category: 'BEAUTY',
    description: 'American skincare brand',
    fullDescription:
        'Kiehl\'s is an American cosmetics brand retailer that specializes in premium skin, hair, and body care products. Founded in 1851, it is one of the oldest skincare brands in the United States.',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxraWVobHMlMjBza2luY2FyZSUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzNTF8MA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Premium skincare products',
      'Heritage and tradition',
      'Hair and body care',
      'Pharmacy-inspired formulas',
    ],
  ),
  LVMHBrand(
    name: 'Urban Decay',
    category: 'BEAUTY',
    description: 'American cosmetics brand',
    fullDescription:
        'Urban Decay is an American cosmetics brand founded in 1996. The brand is known for its edgy, alternative approach to beauty and its high-quality, pigmented makeup products.',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx1cmJhbiUyMGRlY2F5JTIwYmVhdXR5JTIwbHV4dXJ5fGVufDF8fHx8MTc1ODEzMjM1NHww&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Edgy and alternative beauty',
      'High-pigment formulas',
      'Bold color palettes',
      'Cruelty-free products',
    ],
  ),
  LVMHBrand(
    name: 'Too Faced',
    category: 'BEAUTY',
    description: 'American cosmetics brand',
    fullDescription:
        'Too Faced is an American cosmetics brand founded in 1998. The brand is known for its fun, feminine packaging and high-quality makeup products that are both playful and professional.',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0b28lMjBmYWNlZCUyMGJlYXV0eSUyMGx1eHVyeXxlbnwxfHx8fDE3NTgxMzIzNTd8MA&ixlib=rb-4.1.0&q=80&w=1080',
    accentColor: const Color(0xFFFFD700),
    gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
    features: [
      'Fun and feminine designs',
      'High-quality formulations',
      'Playful yet professional',
      'Innovative product concepts',
    ],
  ),
];
