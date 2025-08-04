// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/card_wallet_bloc.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/agents_products_bloc.dart';
import '../widgets/discover_app_bar.dart';
import '../widgets/discover_search_bar.dart';
import '../widgets/discover_content.dart';
import '../widgets/discover_cart_dialog.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class DiscoverPageRefactored extends StatefulWidget {
  const DiscoverPageRefactored({super.key});

  @override
  State<DiscoverPageRefactored> createState() => _DiscoverPageRefactoredState();
}

class _DiscoverPageRefactoredState extends State<DiscoverPageRefactored> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSearchExpanded = false;
  bool _isSearchVisible = true;

  // Theme colors matching other pages
  static const Color lightGreyBackground = Color(0xFFF9F9F9);

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

  void _showCartDialog() {
    final cartBloc = context.read<CartBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return DiscoverCartDialog(cartBloc: cartBloc);
      },
    );
  }

  void _onSearch(String query) {
    // Search functionality placeholder
    if (query.isNotEmpty) {
      // Perform search
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: $query'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      appBar: DiscoverAppBar(
        onSearchToggle: _toggleSearch,
        onCartPressed: _showCartDialog,
        isSearchExpanded: _isSearchExpanded,
        isSearchVisible: _isSearchVisible,
      ),
      body: BlocListener<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartAgentConflict) {
            // Handle cart conflict - this could be moved to a separate service
            _showCartConflictDialog(state);
          }
        },
        child: DiscoverContent(
          scrollController: _scrollController,
          onRefresh: _onRefresh,
        ),
      ),
      bottomNavigationBar: _isSearchExpanded
          ? DiscoverSearchBar(
              controller: searchController,
              focusNode: searchFocusNode,
              isExpanded: _isSearchExpanded,
              isVisible: _isSearchVisible,
              onToggle: _toggleSearch,
              onSearch: _onSearch,
            )
          : null,
    );
  }

  void _showCartConflictDialog(CartAgentConflict state) {
    final cartBloc = context.read<CartBloc>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: cartBloc,
          child: AlertDialog(
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
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Clear cart and add the new item
                  cartBloc.add(const ClearCartEvent());
                  cartBloc.add(
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
                      backgroundColor: const Color(0xFFA342FF),
                    ),
                  );
                },
                child: const Text(
                  'Clear & Add',
                  style: TextStyle(
                    color: Color(0xFFA342FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
