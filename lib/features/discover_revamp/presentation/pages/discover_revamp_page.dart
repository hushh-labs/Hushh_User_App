import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/discover_revamp_bloc.dart';
import '../widgets/discover_header.dart';
import '../widgets/discover_item_card.dart';
import '../widgets/section_heading.dart';
import '../widgets/icon_grid.dart';
import '../widgets/top_categories_row.dart';
import '../widgets/new_launches_grid.dart';
import '../widgets/brands_marquee.dart';
import '../widgets/service_banner_carousel.dart';
// import '../widgets/brands_marquee.dart';
// import '../widgets/luxury_categories_grid.dart';
import '../widgets/concierge_agent_card.dart';
import 'partner_agents_page.dart';
import '../../../discover/presentation/pages/all_brands_page.dart';

class DiscoverRevampPage extends StatefulWidget {
  const DiscoverRevampPage({super.key});

  @override
  State<DiscoverRevampPage> createState() => _DiscoverRevampPageState();
}

class _DiscoverRevampPageState extends State<DiscoverRevampPage> {
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // AppBar removed as requested. Header is rendered inside the body.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: BlocBuilder<DiscoverRevampBloc, DiscoverRevampState>(
        builder: (context, state) {
          final headerWidgets = <Widget>[
            const SizedBox(height: 8),
            DiscoverHeader(
              primaryPurple: primaryPurple,
              primaryPink: primaryPink,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onFilterTap: () {},
            ),
            const SizedBox(height: 16),
            const ServiceBannerCarousel(),
            const SizedBox(height: 0),
            // New Luxury Categories Section (old hidden below)
            // const LuxuryCategoriesGrid(), // hidden per request

            // OLD CATEGORIES HIDDEN
            // const SectionHeading(
            //   title: 'Explore Top Categories',
            //   actionText: '',
            //   leadingIcon: Icons.auto_awesome,
            // ),
            // const SizedBox(height: 16),
            // ... old grid removed for brevity
            const SizedBox(height: 0),
            const SectionHeading(
              title: 'Explore Top Categories',
              actionText: '',
              leadingIcon: Icons.auto_awesome,
            ),
            const SizedBox(height: 6),
            const TopCategoriesRow(),
            SectionHeading(
              title: 'Partner Brands',
              actionText: 'View all',
              leadingIcon: Icons.auto_awesome,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PartnerAgentsPage(),
                  ),
                );
              },
            ),
            const BrandsMarquee(),

            // Concierge Agents Section
            SectionHeading(
              title: 'Partner Agents',
              actionText: 'View all',
              leadingIcon: Icons.person_outline,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PartnerAgentsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ConciergeAgentsGrid(
              agents: [
                ConciergeAgentData(
                  name: 'Sophia Chen',
                  location: 'Beverly Hills, CA',
                  services: 'Luxury Fashion, Handbags',
                  brand: 'Louis Vuitton',
                  industry: 'Fashion & Leather Goods',
                  rating: 4.9,
                  imageUrl:
                      'https://images.unsplash.com/photo-1580489944761-15a19d654956?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMGJ1c2luZXNzJTIwcHJvZmVzc2lvbmFsfGVufDF8fHx8MTc1ODEzNTI3MXww&ixlib=rb-4.1.0&q=80&w=1080',
                ),
                ConciergeAgentData(
                  name: 'Marcus Webb',
                  location: 'Beverly Hills, CA',
                  services: 'Fine Jewelry, Watches',
                  brand: 'Cartier',
                  industry: 'Jewelry & Watches',
                  rating: 4.8,
                  imageUrl:
                      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYW4lMjBidXNpbmVzcyUyMHByb2Zlc3Npb25hbHxlbnwxfHx8fDE3NTgxMzUyNzR8MA&ixlib=rb-4.1.0&q=80&w=1080',
                ),
                ConciergeAgentData(
                  name: 'Isabella Rodriguez',
                  location: 'Manhattan, NY',
                  services: 'Art & Collectibles',
                  brand: 'Sotheby\'s',
                  industry: 'Art & Collectibles',
                  rating: 4.9,
                  imageUrl:
                      'https://images.unsplash.com/photo-1494790108755-2616b612b786?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHByb2Zlc3Npb25hbCUyMHBvcnRyYWl0fGVufDF8fHx8MTc1ODEzNTI3N3ww&ixlib=rb-4.1.0&q=80&w=1080',
                ),
                ConciergeAgentData(
                  name: 'Alexander Kim',
                  location: 'Miami, FL',
                  services: 'Luxury Cars, Real Estate',
                  brand: 'Aston Martin',
                  industry: 'Automotive & Real Estate',
                  rating: 4.7,
                  imageUrl:
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYW4lMjBwcm9mZXNzaW9uYWwlMjBwb3J0cmFpdHxlbnwxfHx8fDE3NTgxMzUyODB8MA&ixlib=rb-4.1.0&q=80&w=1080',
                ),
              ],
              onAgentTap: (agent) {
                // Handle agent tap
                print('Tapped on ${agent.name}');
              },
              onFavoriteTap: (agent) {
                // Handle favorite tap
                print('Favorited ${agent.name}');
              },
            ),
            const SizedBox(height: 16),

            /* Popular places moved below top categories (temporarily hidden)
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Popular places',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'View all',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SegmentChips(),
            const SizedBox(height: 20),
            */
            const SizedBox(height: 16),
            const SectionHeading(
              title: 'New Launches',
              actionText: 'View all',
              leadingIcon: Icons.campaign_outlined,
            ),
            const SizedBox(height: 12),
            IconGrid(
              crossAxisCount: 4,
              items: [
                GridItem(
                  label: 'Pet Services',
                  icon: Icons.pets,
                  gradientColors: const [Color(0xFFFFE0E6), Color(0xFFFFB3C6)],
                  iconColor: const Color(0xFFE91E63),
                ),
                GridItem(
                  label: 'Visa Experts',
                  icon: Icons.card_travel,
                  gradientColors: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  iconColor: const Color(0xFF2196F3),
                ),
                GridItem(
                  label: 'Documentation',
                  icon: Icons.description,
                  gradientColors: const [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                  iconColor: const Color(0xFF9C27B0),
                ),
                GridItem(
                  label: 'Home Care',
                  icon: Icons.home_repair_service,
                  gradientColors: const [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                  iconColor: const Color(0xFF4CAF50),
                ),
                GridItem(
                  label: 'Laundry',
                  icon: Icons.local_laundry_service,
                  gradientColors: const [Color(0xFFFFF3E0), Color(0xFFFFCC02)],
                  iconColor: const Color(0xFFFF9800),
                ),
                GridItem(
                  label: 'Appliance',
                  icon: Icons.build,
                  gradientColors: const [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                  iconColor: const Color(0xFF009688),
                ),
                GridItem(
                  label: 'More',
                  icon: Icons.more_horiz,
                  gradientColors: const [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                  iconColor: const Color(0xFF757575),
                ),
                GridItem(
                  label: 'Support',
                  icon: Icons.support_agent,
                  gradientColors: const [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                  iconColor: const Color(0xFF673AB7),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const SectionHeading(
              title: 'Tech',
              actionText: 'View all',
              leadingIcon: Icons.memory_outlined,
            ),
            const SizedBox(height: 12),
            IconGrid(
              crossAxisCount: 4,
              items: [
                GridItem(
                  label: 'Hotels',
                  icon: Icons.hotel,
                  gradientColors: const [Color(0xFFE8F4FD), Color(0xFFD6EEF7)],
                  iconColor: const Color(0xFF2B5CE6),
                ),
                GridItem(
                  label: 'Flights',
                  icon: Icons.flight_takeoff,
                  gradientColors: const [Color(0xFFFFE8E8), Color(0xFFFFCCCC)],
                  iconColor: const Color(0xFFE53E3E),
                ),
                GridItem(
                  label: 'Food',
                  icon: Icons.restaurant,
                  gradientColors: const [Color(0xFFFFF8E1), Color(0xFFFFE082)],
                  iconColor: const Color(0xFFFFB300),
                ),
                GridItem(
                  label: 'Places',
                  icon: Icons.place_outlined,
                  gradientColors: const [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                  iconColor: const Color(0xFF4CAF50),
                ),
                GridItem(
                  label: 'Events',
                  icon: Icons.event,
                  gradientColors: const [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                  iconColor: const Color(0xFF9C27B0),
                ),
                GridItem(
                  label: 'Beach',
                  icon: Icons.beach_access,
                  gradientColors: const [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                  iconColor: const Color(0xFF00BCD4),
                ),
                GridItem(
                  label: 'Hiking',
                  icon: Icons.terrain,
                  gradientColors: const [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
                  iconColor: const Color(0xFF8D6E63),
                ),
                GridItem(
                  label: 'More',
                  icon: Icons.more_horiz,
                  gradientColors: const [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                  iconColor: const Color(0xFF757575),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeading(
              title: 'Fashion',
              actionText: 'View all',
              leadingIcon: Icons.local_mall_outlined,
            ),
            const SizedBox(height: 12),
            IconGrid(
              crossAxisCount: 4,
              items: [
                GridItem(
                  label: 'Shoes',
                  icon: Icons.directions_run,
                  gradientColors: const [Color(0xFFFFE8CC), Color(0xFFFFD93D)],
                  iconColor: const Color(0xFFE65100),
                ),
                GridItem(
                  label: 'Bags',
                  icon: Icons.work_outline,
                  gradientColors: const [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                  iconColor: const Color(0xFF2E7D32),
                ),
                GridItem(
                  label: 'Watches',
                  icon: Icons.watch_outlined,
                  gradientColors: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  iconColor: const Color(0xFF1976D2),
                ),
                GridItem(
                  label: 'Jewelry',
                  icon: Icons.diamond_outlined,
                  gradientColors: const [Color(0xFFFCE4EC), Color(0xFFF8BBD9)],
                  iconColor: const Color(0xFFAD1457),
                ),
                GridItem(
                  label: 'Sunglasses',
                  icon: Icons.dark_mode,
                  gradientColors: const [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                  iconColor: const Color(0xFF512DA8),
                ),
                GridItem(
                  label: 'Apparel',
                  icon: Icons.checkroom_outlined,
                  gradientColors: const [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                  iconColor: const Color(0xFF00695C),
                ),
                GridItem(
                  label: 'Beauty',
                  icon: Icons.brush_outlined,
                  gradientColors: const [Color(0xFFFFE0E6), Color(0xFFFFB3C6)],
                  iconColor: const Color(0xFFC2185B),
                ),
                GridItem(
                  label: 'All',
                  icon: Icons.category_outlined,
                  gradientColors: const [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                  iconColor: const Color(0xFF7B1FA2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeading(
              title: 'More',
              actionText: 'View all',
              leadingIcon: Icons.more_horiz,
            ),
            const SizedBox(height: 12),
            IconGrid(
              crossAxisCount: 4,
              items: [
                GridItem(
                  label: 'Experiences',
                  icon: Icons.explore_outlined,
                  gradientColors: const [Color(0xFFFFE0B2), Color(0xFFFFB74D)],
                  iconColor: const Color(0xFFE65100),
                ),
                GridItem(
                  label: 'Guides',
                  icon: Icons.menu_book_outlined,
                  gradientColors: const [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                  iconColor: const Color(0xFF388E3C),
                ),
                GridItem(
                  label: 'Transport',
                  icon: Icons.directions_car_outlined,
                  gradientColors: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  iconColor: const Color(0xFF1976D2),
                ),
                GridItem(
                  label: 'Deals',
                  icon: Icons.local_offer_outlined,
                  gradientColors: const [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
                  iconColor: const Color(0xFFD32F2F),
                ),
                GridItem(
                  label: 'Favorites',
                  icon: Icons.favorite_border,
                  gradientColors: const [Color(0xFFFFE0E6), Color(0xFFFFB3C6)],
                  iconColor: const Color(0xFFE91E63),
                ),
                GridItem(
                  label: 'Wishlist',
                  icon: Icons.bookmark_border,
                  gradientColors: const [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                  iconColor: const Color(0xFF8E24AA),
                ),
                GridItem(
                  label: 'Support',
                  icon: Icons.support_agent,
                  gradientColors: const [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                  iconColor: const Color(0xFF00838F),
                ),
                GridItem(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  gradientColors: const [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                  iconColor: const Color(0xFF616161),
                ),
              ],
            ),
          ];

          if (state.isLoading) {
            return ListView(
              children: [
                ...headerWidgets,
                const SizedBox(height: 80),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 80),
              ],
            );
          }
          if (state.errorMessage != null) {
            return ListView(
              children: [
                ...headerWidgets,
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(child: Text(state.errorMessage!)),
                ),
              ],
            );
          }

          if (state.items.isEmpty) {
            return ListView(
              children: [
                ...headerWidgets,
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    'No items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 0, bottom: 12),
            itemCount: headerWidgets.length + state.items.length,
            itemBuilder: (context, index) {
              if (index < headerWidgets.length) {
                return headerWidgets[index];
              }
              final item = state.items[index - headerWidgets.length];
              return DiscoverItemCard(
                title: item.title,
                subtitle: 'ID: ${item.id}',
                imageUrl: item.imageUrl,
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}

// Deprecated local widget (replaced by DiscoverHeader in widgets/).
// Keeping it commented for reference if needed later.
/* class _HeaderCard extends StatelessWidget {
  final Color primaryPurple;
  final Color primaryPink;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  const _HeaderCard({
    required this.primaryPurple,
    required this.primaryPink,
    required this.searchController,
    required this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: const AssetImage('assets/avtar_agent.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hi, David 👋',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Explore the world',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6D6D7A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _CartIconInline(),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6E6EC)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search places',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE6E6EC),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} */

/* class _SegmentChips extends StatelessWidget {
  const _SegmentChips();

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, {bool selected = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF0F0F3),
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF9A9AA6),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          pill('Most Viewed', selected: true),
          const SizedBox(width: 12),
          pill('Nearby'),
          const SizedBox(width: 12),
          pill('Latest'),
        ],
      ),
    );
  }
} */

// Deprecated local inline cart (moved to DiscoverHeader widget)
/* class _CartIconInline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        int cartItemCount = 0;
        if (state is CartLoaded) cartItemCount = state.totalItems;
        return Stack(
          children: [
            IconButton(
              tooltip: 'Cart',
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.black87,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart coming soon…')),
                );
              },
            ),
            if (cartItemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE54D60), Color(0xFFA342FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$cartItemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
} */
