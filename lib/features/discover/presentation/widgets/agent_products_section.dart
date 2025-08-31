import 'package:flutter/material.dart';
import '../../data/models/agent_product_model.dart';
import '../pages/agent_profile.dart';
import 'product_tile.dart';
import '../../domain/entities/enums.dart';

class AgentProductsSection extends StatelessWidget {
  final Map<String, dynamic> agent;
  final List<Map<String, dynamic>> products;
  final Function(String) onProductClicked;
  final Function(String) onProductInventoryIncremented;
  final Function(String) onProductInventoryDecremented;
  final Function(String) onAddToCart;
  final Function() onLoadMoreProducts;
  final bool hasMoreProducts;
  final bool isLoadingMoreProducts;

  const AgentProductsSection({
    super.key,
    required this.agent,
    required this.products,
    required this.onProductClicked,
    required this.onProductInventoryIncremented,
    required this.onProductInventoryDecremented,
    required this.onAddToCart,
    required this.onLoadMoreProducts,
    required this.hasMoreProducts,
    required this.isLoadingMoreProducts,
  });

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
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple agent header with profile picture
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Profile picture
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: agent['avatar'] != null && agent['avatar']!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            agent['avatar']!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            _getInitials(agent['name'] ?? 'A'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent['name'] ?? 'Unknown Agent',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        agent['company'] ?? 'N/A',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to agent's profile page with products and categories
                    final agentWithProducts = Map<String, dynamic>.from(agent);
                    agentWithProducts['products'] = products;
                    agentWithProducts['categories'] = agent['categories'] ?? [];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgentProfile(
                          agent: agentWithProducts,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Show more',
                    style: TextStyle(
                      color: Color(0xFFA342FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Products List with Infinite Scroll
          SizedBox(
            height: 240, // Updated height as requested
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: products.length + (hasMoreProducts ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the end for infinite scroll
                if (index == products.length) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFFA342FF),
                      ),
                    ),
                  );
                }

                final product = products[index];
                return Container(
                  width: 180, // Fixed width for each product tile
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductTile(
                    product: AgentProductModel(
                      id: product['id'],
                      productName: product['name'],
                      productPrice: product['price'].toDouble(),
                      stockQuantity: product['stock'],
                      productImage: product['imageUrl'],
                      createdAt: product['isNew']
                          ? DateTime.now().subtract(const Duration(hours: 2))
                          : DateTime.now().subtract(const Duration(days: 5)),
                    ),
                    specifyDimensions: true,
                    productTileType: ProductTileType.viewProducts,
                    isProductSelected: false,
                    onProductClicked: onProductClicked,
                    onProductInventoryIncremented:
                        onProductInventoryIncremented,
                    onProductInventoryDecremented:
                        onProductInventoryDecremented,
                    onAddToCart: () {
                      onAddToCart(product['id']);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
