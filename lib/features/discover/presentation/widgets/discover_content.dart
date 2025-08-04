import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/agents_products_bloc.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../../data/models/agent_product_model.dart';
import '../pages/agent_profile.dart';
import 'discover_item_shimmer.dart';
import 'agent_products_section.dart';

class DiscoverContent extends StatelessWidget {
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  const DiscoverContent({
    super.key,
    required this.scrollController,
    required this.onRefresh,
  });

  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primaryPurple,
      child: BlocBuilder<AgentsProductsBloc, AgentsProductsState>(
        builder: (context, agentsProductsState) {
          if (agentsProductsState is AgentsProductsLoading) {
            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: 3,
              itemBuilder: (context, index) => const DiscoverItemShimmer(),
            );
          }

          if (agentsProductsState is AgentsProductsLoaded) {
            if (agentsProductsState.agents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryPurple, primaryPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.search_off,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No agents found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try refreshing the page',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // Filter agents with products
            final agentsWithProducts = agentsProductsState.agents.where((
              agent,
            ) {
              final products =
                  agentsProductsState.agentProducts[agent.agentId] ?? [];
              return products.isNotEmpty;
            }).toList();

            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount:
                  agentsWithProducts.length +
                  (agentsProductsState.hasMoreAgents ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the end for infinite scroll
                if (index == agentsWithProducts.length) {
                  return Container(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryPurple),
                    ),
                  );
                }

                final agent = agentsWithProducts[index];
                final products =
                    agentsProductsState.agentProducts[agent.agentId] ?? [];

                return AgentProductsSection(
                  agent: {
                    'id': agent.agentId,
                    'name': agent.name,
                    'company': agent.brandName,
                    'avatar':
                        null, // You can add avatar field to AgentModel if needed
                    'categories': agent.categories,
                  },
                  products: products
                      .map(
                        (product) => {
                          'id': product.id,
                          'name': product.productName,
                          'price': product.productPrice,
                          'originalPrice': product
                              .productPrice, // No original price field in your structure
                          'stock': product.stockQuantity,
                          'imageUrl': product.productImage,
                          'isNew': false, // No isNew field in your structure
                          'discountPercentage':
                              null, // No discount field in your structure
                        },
                      )
                      .toList(),
                  hasMoreProducts:
                      agentsProductsState.hasMoreProducts[agent.agentId] ??
                      false,
                  isLoadingMoreProducts:
                      agentsProductsState.isLoadingMoreProducts[agent
                          .agentId] ??
                      false,
                  onProductClicked: (productId) {
                    // Product click handled silently
                  },
                  onProductInventoryIncremented: (productId) {
                    context.read<InventoryBloc>().add(
                      UpdateProductStockQuantityEvent(
                        productId: productId,
                        newQuantity: 10, // Mock quantity
                      ),
                    );
                  },
                  onProductInventoryDecremented: (productId) {
                    context.read<InventoryBloc>().add(
                      UpdateProductStockQuantityEvent(
                        productId: productId,
                        newQuantity: 5, // Mock quantity
                      ),
                    );
                  },
                  onAddToCart: (productId) {
                    final product = products.firstWhere(
                      (p) => p.id == productId,
                      orElse: () => AgentProductModel(
                        id: productId,
                        productName: 'Unknown Product',
                        productPrice: 0.0,
                        stockQuantity: 0,
                      ),
                    );

                    context.read<CartBloc>().add(
                      AddToCartEvent(
                        product: product,
                        agentId: agent.agentId,
                        agentName: agent.name,
                      ),
                    );
                  },
                  onLoadMoreProducts: () {
                    context.read<AgentsProductsBloc>().add(
                      LoadMoreAgentProducts(agent.agentId),
                    );
                  },
                );
              },
            );
          }

          if (agentsProductsState is AgentsProductsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryPurple, primaryPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    agentsProductsState.message,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Center(child: CircularProgressIndicator(color: primaryPurple));
        },
      ),
    );
  }
}
