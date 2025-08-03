// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/card_wallet_bloc.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/agents_products_bloc.dart';
import '../../domain/entities/enums.dart';
import '../../data/models/agent_product_model.dart';
import '../widgets/product_tile.dart';
import 'agent_profile.dart';
import 'order_confirmation_page.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSearchExpanded = false;
  bool _isSearchVisible = true;

  // Theme colors matching other pages
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);
  static const Color lightGreyBackground = Color(0xFFF9F9F9);
  static const Color borderColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    // Load data when widget initializes
    context.read<DiscoverBloc>().add(const LoadDiscoverData());
    context.read<CardWalletBloc>().add(const LoadProducts());
    context.read<CartBloc>().add(const LoadCartEvent());
    context.read<AgentsProductsBloc>().add(const LoadAgentsAndProducts());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<DiscoverBloc>().add(const LoadDiscoverData());
    context.read<CardWalletBloc>().add(const LoadProducts());
    context.read<AgentsProductsBloc>().add(const LoadAgentsAndProducts());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more agents when scrolling near bottom
      final agentsProductsState = context.read<AgentsProductsBloc>().state;
      if (agentsProductsState is AgentsProductsLoaded &&
          agentsProductsState.hasMoreAgents &&
          !agentsProductsState.isLoadingMore) {
        context.read<AgentsProductsBloc>().add(const LoadMoreAgents());
      }
    }

    // Auto-collapse search bar on scroll
    if (_scrollController.position.pixels > 50 && _isSearchVisible) {
      setState(() {
        _isSearchVisible = false;
        _isSearchExpanded = false;
      });
    } else if (_scrollController.position.pixels <= 50 && !_isSearchVisible) {
      setState(() {
        _isSearchVisible = true;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        searchFocusNode.requestFocus();
      } else {
        searchFocusNode.unfocus();
        searchController.clear();
      }
    });
  }

  void _showCartConflictDialog(CartAgentConflict state) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cart Conflict',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            'You have items from ${state.currentAgentName} in your cart. '
            'Would you like to clear your cart and add items from ${state.newAgentName} instead?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear cart and add the new item
                context.read<CartBloc>().add(const ClearCartEvent());
                context.read<CartBloc>().add(
                  AddToCartEvent(
                    product: state.product,
                    agentId: state.product.id
                        .split('_')
                        .first, // Extract agent ID from product ID
                    agentName: state.newAgentName,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cart cleared and ${state.product.productName} added!',
                    ),
                    backgroundColor: primaryPurple,
                  ),
                );
              },
              child: Text(
                'Clear & Add',
                style: TextStyle(
                  color: primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCartDialog() {
    final cartBloc = context.read<CartBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: cartBloc,
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              if (cartState is CartLoaded && cartState.items.isNotEmpty) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Your Cart',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Agent info
                      if (cartState.currentAgentName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Agent: ${cartState.currentAgentName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Cart items
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: cartState.items.length,
                          itemBuilder: (context, index) {
                            final item = cartState.items[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  // Product image
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child:
                                        item.product.imageUrl != null &&
                                            item.product.imageUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              item.product.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.image,
                                                      color: Colors.grey[400],
                                                    );
                                                  },
                                            ),
                                          )
                                        : Icon(
                                            Icons.image,
                                            color: Colors.grey[400],
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Product details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (item.hasValidBid &&
                                            item.bidAmount != null)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'USD ${item.product.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 12,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF4CAF50,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'HUSHHCOINS',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'USD ${item.discountedPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Color(0xFF4CAF50),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            'USD ${item.product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Quantity controls
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (item.quantity > 1) {
                                            context.read<CartBloc>().add(
                                              UpdateCartItemQuantityEvent(
                                                productId: item.id,
                                                quantity: item.quantity - 1,
                                              ),
                                            );
                                          } else {
                                            context.read<CartBloc>().add(
                                              RemoveFromCartEvent(item.id),
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.remove,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          context.read<CartBloc>().add(
                                            UpdateCartItemQuantityEvent(
                                              productId: item.id,
                                              quantity: item.quantity + 1,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Total
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            // Show discount if any items have bids
                            if (cartState.items.any((item) => item.hasValidBid))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Total Savings',
                                      style: TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'USD ${cartState.items.fold(0.0, (total, item) => total + item.discountAmount).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'USD ${cartState.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                context.read<CartBloc>().add(
                                  const ClearCartEvent(),
                                );
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Clear Cart',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () async {
                                // Get agent details from Firebase using currentAgentId from cart
                                String agentName = 'Unknown Agent';
                                String brandName = 'Unknown Brand';
                                String phone = '+91';

                                if (cartState.currentAgentId != null) {
                                  try {
                                    final agentDoc = await FirebaseFirestore
                                        .instance
                                        .collection('Hushhagents')
                                        .doc(cartState.currentAgentId)
                                        .get();

                                    if (agentDoc.exists) {
                                      final agentData = agentDoc.data()!;
                                      agentName =
                                          agentData['name'] ?? 'Unknown Agent';
                                      brandName =
                                          agentData['brandName'] ??
                                          'Unknown Brand';
                                      phone = agentData['phone'] ?? '+91';
                                    }
                                  } catch (e) {
                                    debugPrint(
                                      'Error fetching agent details: $e',
                                    );
                                  }
                                }

                                // Close modal and navigate in one go
                                Navigator.pop(dialogContext);

                                // Use a small delay to ensure modal is closed
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );

                                // Navigate to order confirmation
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider.value(
                                        value: context.read<CartBloc>(),
                                        child: OrderConfirmationPage(
                                          cartItems: cartState.items,
                                          agentName: agentName,
                                          brandName: brandName,
                                          totalPrice: cartState.totalPrice,
                                          agentPhone: phone,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Checkout'),
                            ),
                          ],
                        ),
                      ),
                      // Bottom safe area
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                );
              } else {
                return Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: const Center(child: Text('Cart is empty')),
                );
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Discover icon with gradient background
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryPurple, primaryPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.explore, size: 24, color: Colors.white),
              ),
            ),
            const Text(
              'Discover',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
            const Spacer(),
            // Cart button
            BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                int cartItemCount = 0;
                if (cartState is CartLoaded) {
                  cartItemCount = cartState.totalItems;
                }

                return IconButton(
                  onPressed: _showCartDialog,
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.black54,
                        size: 24,
                      ),
                      if (cartItemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryPink, primaryPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              cartItemCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // Search icon
            IconButton(
              onPressed: _toggleSearch,
              icon: Icon(
                _isSearchExpanded ? Icons.close : Icons.search,
                color: Colors.black54,
                size: 24,
              ),
            ),
          ],
        ),
        bottom: _isSearchExpanded
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search for anything...',
                        prefixIcon: Icon(Icons.search, color: primaryPurple),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        // Search functionality placeholder
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          // Perform search
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Searching for: $value'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: BlocListener<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartAgentConflict) {
            _showCartConflictDialog(state);
          }
        },
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: primaryPurple,
          child: BlocBuilder<AgentsProductsBloc, AgentsProductsState>(
            builder: (context, agentsProductsState) {
              if (agentsProductsState is AgentsProductsLoading) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                          child: CircularProgressIndicator(
                            color: primaryPurple,
                          ),
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
                              'isNew':
                                  false, // No isNew field in your structure
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

              return Center(
                child: CircularProgressIndicator(color: primaryPurple),
              );
            },
          ),
        ),
      ),
    );
  }
}

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
                        builder: (context) =>
                            AgentProfile(agent: agentWithProducts),
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

// Enhanced loading widget for discover items with proper shimmer animation
class DiscoverItemShimmer extends StatefulWidget {
  const DiscoverItemShimmer({super.key});

  @override
  State<DiscoverItemShimmer> createState() => _DiscoverItemShimmerState();
}

class _DiscoverItemShimmerState extends State<DiscoverItemShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildShimmerContainer({
    required double height,
    double? width,
    double borderRadius = 8.0,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFF0F0F0),
                Color(0xFFE0E0E0),
                Color(0xFFF0F0F0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer header with agent info (simplified design)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Agent avatar shimmer
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Agent info shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerContainer(height: 16, width: 120),
                      const SizedBox(height: 4),
                      _buildShimmerContainer(height: 12, width: 80),
                    ],
                  ),
                ),
                // Show more button shimmer
                _buildShimmerContainer(height: 16, width: 60),
              ],
            ),
          ),
          // Shimmer products list
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image shimmer
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Product name shimmer
                      _buildShimmerContainer(height: 14, width: 100),
                      const SizedBox(height: 4),
                      // Price shimmer
                      _buildShimmerContainer(height: 12, width: 60),
                      const SizedBox(height: 4),
                      // Stock shimmer
                      _buildShimmerContainer(height: 10, width: 40),
                    ],
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
