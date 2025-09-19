import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../discover/presentation/bloc/cart_bloc.dart';

class DiscoverHeader extends StatelessWidget {
  final Color primaryPurple;
  final Color primaryPink;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback? onFilterTap;

  const DiscoverHeader({
    super.key,
    required this.primaryPurple,
    required this.primaryPink,
    required this.searchController,
    required this.searchFocusNode,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          // Edge-to-edge header: no card background, radius or shadow
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: left column (title + location) and right actions (cart + profile)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discover',
                          style: TextStyle(
                            color: Color(0xFF1D1D1F),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: Color(0xFF6E6E73),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Beverly Hills, CA',
                              style: TextStyle(
                                color: Color(0xFF6E6E73),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '›',
                              style: TextStyle(color: Color(0xFF6E6E73)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Cart button with badge
                      BlocBuilder<CartBloc, CartState>(
                        builder: (context, state) {
                          int cartItemCount = 0;
                          if (state is CartLoaded)
                            cartItemCount = state.totalItems;
                          return Stack(
                            children: [
                              IconButton(
                                tooltip: 'Cart',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cart coming soon…'),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Color(0xFF1D1D1F),
                                ),
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
                                        colors: [
                                          Color(0xFFE54D60),
                                          Color(0xFFA342FF),
                                        ],
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
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D1D1F), // Apple black
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Apple card-style background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                  ), // iOS separator gray
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search,
                      color: Color(0xFF6E6E73), // Apple secondary
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        cursorColor: const Color(0xFF1D1D1F),
                        style: const TextStyle(
                          color: Color(0xFF1D1D1F),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Search By 'Luxury Brand'",
                          hintStyle: TextStyle(
                            color: Color(0x806E6E73), // 50% Apple secondary
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: const Color(0xFFE5E5EA),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onFilterTap,
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: Color(0xFF6E6E73), // Apple monochrome grey
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 0),
              // Removed the "List With Us" and "Query" buttons as requested
            ],
          ),
        ),
      ),
    );
  }
}

// Cart badge inline widget moved into header and notifications/menu removed
