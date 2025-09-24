import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/concierge_agent_card.dart';
import '../widgets/section_heading.dart';
import '../../../../core/routing/app_router.dart';

class SearchResultRevampPage extends StatefulWidget {
  final String? initialQuery;
  final List<String>? selectedFilters;

  const SearchResultRevampPage({
    super.key,
    this.initialQuery,
    this.selectedFilters,
  });

  @override
  State<SearchResultRevampPage> createState() => _SearchResultRevampPageState();
}

class _SearchResultRevampPageState extends State<SearchResultRevampPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _selectedFilters = [];
  List<ConciergeAgentData> _agents = [];
  List<List<SearchProduct>> _agentProducts = [];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _selectedFilters =
        widget.selectedFilters ??
        [
          'Fashion',
          'Handbags',
          'Luxury',
          'Jewelry',
          'Watches',
          'Beauty',
        ]; // Mock filters for demonstration
    _loadMockData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Mock agents data
    _agents = [
      ConciergeAgentData(
        name: 'Sophia Chen',
        location: 'Beverly Hills, CA',
        services: 'Luxury Fashion, Handbags',
        brand: 'Louis Vuitton',
        industry: 'Fashion & Leather Goods',
        rating: 4.9,
        imageUrl:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHBvcnRyYWl0fGVufDF8fHx8MTc1ODEyNzY2MXww&ixlib=rb-4.1.0&q=80&w=400',
      ),
      ConciergeAgentData(
        name: 'Marcus Webb',
        location: 'New York, NY',
        services: 'Jewelry, Watches',
        brand: 'Cartier',
        industry: 'Luxury Jewelry',
        rating: 4.8,
        imageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYW4lMjBwb3J0cmFpdHxlbnwxfHx8fDE3NTgxMjc2NjF8MA&ixlib=rb-4.1.0&q=80&w=400',
      ),
      ConciergeAgentData(
        name: 'Elena Rodriguez',
        location: 'Paris, France',
        services: 'Couture, Beauty',
        brand: 'Dior',
        industry: 'Fashion & Beauty',
        rating: 4.9,
        imageUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMGJ1c2luZXNzfGVufDF8fHx8MTc1ODEzNTI3N3ww&ixlib=rb-4.1.0&q=80&w=400',
      ),
    ];

    // Mock products for each agent
    _agentProducts = [
      // Sophia Chen's products
      [
        SearchProduct(
          id: '1',
          name: 'Louis Vuitton Neverfull MM',
          brand: 'Louis Vuitton',
          price: 1850.0,
          imageUrl:
              'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsb3VpcyUyMHZ1aXR0b24lMjBoYW5kYmFnfGVufDF8fHx8MTc1ODEyNzY2MXww&ixlib=rb-4.1.0&q=80&w=400',
          category: 'Handbags',
        ),
        SearchProduct(
          id: '2',
          name: 'LV Speedy 30',
          brand: 'Louis Vuitton',
          price: 1650.0,
          imageUrl:
              'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsb3VpcyUyMHZ1aXR0b24lMjBoYW5kYmFnfGVufDF8fHx8MTc1ODEyNzY2MXww&ixlib=rb-4.1.0&q=80&w=400',
          category: 'Handbags',
        ),
        SearchProduct(
          id: '3',
          name: 'LV Wallet',
          brand: 'Louis Vuitton',
          price: 650.0,
          imageUrl:
              'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsb3VpcyUyMHZ1aXR0b24lMjBoYW5kYmFnfGVufDF8fHx8MTc1ODEyNzY2MXww&ixlib=rb-4.1.0&q=80&w=400',
          category: 'Accessories',
        ),
      ],
      // Marcus Webb's products
      [
        SearchProduct(
          id: '4',
          name: 'Cartier Tank Watch',
          brand: 'Cartier',
          price: 3500.0,
          imageUrl:
              'https://images.unsplash.com/photo-1523170335258-f5c6c6f0d0b8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXJ0aWVyJTIwd2F0Y2h8ZW58MXx8fHx8MTc1ODEyNzY2MXww&ixlib=rb-4.1.0&q=80&w=400',
          category: 'Watches',
        ),
        SearchProduct(
          id: '5',
          name: 'Cartier Love Bracelet',
          brand: 'Cartier',
          price: 2800.0,
          imageUrl:
              'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXJ0aWVyJTIwYnJhY2VsZXR8ZW58MXx8fHx8MTc1ODEyNzY2MXww&ixlib=rb-4.1.0&q=80&w=400',
          category: 'Jewelry',
        ),
      ],
      // Elena Rodriguez's products
      [
        SearchProduct(
          id: '6',
          name: 'Dior Lady Bag',
          brand: 'Dior',
          price: 4200.0,
          imageUrl:
              'https://images.unsplash.com/photo-1601835884504-8a4c45324cc1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaW9yJTIwaGFuZGJhZ3xlbnwxfHx8fDE3NTgxMjc2NDF8MA&ixlib=rb-4.1.0&q=80&w=400',
          category: 'Handbags',
        ),
        SearchProduct(
          id: '7',
          name: 'Dior Lipstick Set',
          brand: 'Dior',
          price: 180.0,
          imageUrl:
              'https://images.unsplash.com/photo-1601835884504-8a4c45324cc1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaW9yJTIwYmVhdXR5fGVufDF8fHx8MTc1ODEyNzY0MXww&ixlib=rb-4.1.0&q=80&w=400',
          category: 'Beauty',
        ),
        SearchProduct(
          id: '8',
          name: 'Dior Perfume',
          brand: 'Dior',
          price: 120.0,
          imageUrl:
              'https://images.unsplash.com/photo-1601835884504-8a4c45324cc1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkaW9yJTIwYmVhdXR5fGVufDF8fHx8MTc1ODEyNzY0MXww&ixlib=rb-4.1.0&q=80&w=400',
          category: 'Beauty',
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Apple grey background
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1D1D1F),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Search',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1D1D1F),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Color(0xFF1D1D1F),
                    ),
                    onPressed: () {
                      // Handle favorites
                    },
                  ),
                ],
              ),
            ),

            // Search Bar and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Main Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5EA)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: const InputDecoration(
                              hintText:
                                  'Search for products, brands, agents...',
                              hintStyle: TextStyle(
                                color: Color(0xFF6E6E73),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: const TextStyle(
                              color: Color(0xFF1D1D1F),
                              fontSize: 16,
                            ),
                            onSubmitted: (value) {
                              _performSearch(value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter Button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.tune,
                            color: Color(0xFF1D1D1F),
                            size: 20,
                          ),
                          onPressed: () {
                            // Handle filter
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Bubbles - Always show
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _selectedFilters[index];
                        final isActive = index == 0; // First filter is active
                        return GestureDetector(
                          onTap: () {
                            // Handle filter selection
                            setState(() {
                              // Move selected filter to front
                              final selectedFilter = _selectedFilters.removeAt(
                                index,
                              );
                              _selectedFilters.insert(0, selectedFilter);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFFFD700) // Yellow for active
                                  : const Color(
                                      0xFFF2F2F7,
                                    ), // Grey for inactive
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFFE5E5EA),
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(
                                        0xFF1D1D1F,
                                      ) // Black text for active
                                    : const Color(
                                        0xFF6E6E73,
                                      ), // Grey text for inactive
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agents Section
                    if (_agents.isNotEmpty) ...[
                      const SectionHeading(
                        title: 'Agents',
                        leadingIcon: Icons.person_outline,
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _agents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final agent = _agents[index];
                            return SizedBox(
                              width: 140,
                              child: ConciergeAgentCard(
                                name: agent.name,
                                location: agent.location,
                                services: agent.services,
                                brand: agent.brand,
                                industry: agent.industry,
                                rating: agent.rating,
                                imageUrl: agent.imageUrl,
                                onTap: () {
                                  // Navigate to Q&A page when agent is tapped
                                  context.pushNamed(
                                    'qna',
                                    extra: QnAPageArgs(
                                      agentId: agent.name
                                          .toLowerCase()
                                          .replaceAll(' ', '_'),
                                      agentName: agent.name,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Products by Agent Section
                    if (_agentProducts.isNotEmpty) ...[
                      const SectionHeading(
                        title: 'Products by Agent',
                        leadingIcon: Icons.shopping_bag_outlined,
                      ),
                      ...List.generate(_agentProducts.length, (agentIndex) {
                        final agent = _agents[agentIndex];
                        final products = _agentProducts[agentIndex];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Agent header for this row
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: NetworkImage(
                                      agent.imageUrl,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${agent.name} - ${agent.brand}',
                                    style: const TextStyle(
                                      color: Color(0xFF1D1D1F),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Color(0xFFFFD700),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        agent.rating.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF1D1D1F),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Products horizontal scroll
                            SizedBox(
                              height: 200,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: products.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, productIndex) {
                                  final product = products[productIndex];
                                  return _buildProductCard(product);
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(SearchProduct product) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF5F5F7),
                        child: const Icon(
                          Icons.image,
                          color: Color(0xFF6E6E73),
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6E6E73),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Add to cart functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  onPressed: () {
                                    context.pushNamed('cart');
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D1D1F),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) {
    // Implement search logic here
    print('Searching for: $query');
    print('Filters: $_selectedFilters');
  }
}

// Data Models

class SearchProduct {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String imageUrl;
  final String category;

  SearchProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}
