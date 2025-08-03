import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/agent_profile_tabbar.dart';

class AgentProfile extends StatefulWidget {
  final Map<String, dynamic> agent;

  const AgentProfile({super.key, required this.agent});

  @override
  State<AgentProfile> createState() => _AgentProfileState();
}

class _AgentProfileState extends State<AgentProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final agent = widget.agent;
      final agentCategories = agent['categories'] as List<dynamic>?;

      if (agentCategories != null && agentCategories.isNotEmpty) {
        final categoriesData = <Map<String, dynamic>>[];

        for (final categoryId in agentCategories) {
          final categoryDoc = await FirebaseFirestore.instance
              .collection('agent_categories')
              .doc(categoryId.toString())
              .get();

          if (categoryDoc.exists) {
            final data = categoryDoc.data()!;
            categoriesData.add({
              'id': categoryId,
              'name': data['name'] ?? 'Unknown Category',
              'description': data['description'] ?? '',
            });
          }
        }

        setState(() {
          categories = categoriesData;
          isLoadingCategories = false;
        });
      } else {
        setState(() {
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'A';

    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }
    return 'A';
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final products = agent['products'] as List<dynamic>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agent Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Agent Header Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar with proper image handling
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(52),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        agent['avatar'] != null && agent['avatar']!.isNotEmpty
                        ? NetworkImage(agent['avatar']!)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: agent['avatar'] == null || agent['avatar']!.isEmpty
                        ? Text(
                            _getInitials(agent['name'] ?? 'A'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Agent Name
                Text(
                  agent['name'] ?? 'Agent Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Company
                Text(
                  agent['company'] ?? 'Company',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                // Categories
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoadingCategories)
                  _buildCategoriesShimmer()
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.isNotEmpty
                        ? categories
                              .map(
                                (category) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    category['name'] ?? 'Unknown Category',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList()
                        : [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'No categories available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                  ),
              ],
            ),
          ),
          // Tab Bar
          AgentProfileTabBar(
            tabController: _tabController,
            onTap: (index) {
              _tabController.animateTo(index);
            },
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildLookbooksTab(), _buildProductsTab(products)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookbooksTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Lookbooks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No lookbooks available yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(List<dynamic> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              // Product Image with proper handling
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    product['imageUrl'] != null &&
                        product['imageUrl']!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 40,
                            );
                          },
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.grey, size: 40),
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Product Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product['id'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: \$${(product['price'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat Icon
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat feature coming soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.message, color: Color(0xFFA342FF)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesShimmer() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        3,
        (index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 80 + (index * 20.0), // Different widths for variety
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
