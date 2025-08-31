import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';

class DiscoverAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchToggle;
  final VoidCallback onCartPressed;
  final bool isSearchExpanded;
  final bool isSearchVisible;

  const DiscoverAppBar({
    super.key,
    required this.onSearchToggle,
    required this.onCartPressed,
    required this.isSearchExpanded,
    required this.isSearchVisible,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFFA342FF);
    const Color primaryPink = Color(0xFFE54D60);

    return AppBar(
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
          Builder(
            builder: (context) {
              try {
                return BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
                    int cartItemCount = 0;
                    if (cartState is CartLoaded) {
                      cartItemCount = cartState.totalItems;
                    }

                    return IconButton(
                      onPressed: onCartPressed,
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
                );
              } catch (e) {
                // Fallback when CartBloc is not available
                return IconButton(
                  onPressed: onCartPressed,
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black54,
                    size: 24,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          // Search icon
          IconButton(
            onPressed: onSearchToggle,
            icon: Icon(
              isSearchExpanded ? Icons.close : Icons.search,
              color: Colors.black54,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
