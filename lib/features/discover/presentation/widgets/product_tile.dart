import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/agent_product_model.dart';
import '../../domain/entities/enums.dart';
import '../bloc/cart_bloc.dart';

class ProductTile extends StatefulWidget {
  final AgentProductModel product;
  final bool specifyDimensions;
  final ProductTileType productTileType;
  final bool isProductSelected;
  final Function(String) onProductClicked;
  final Function(String) onProductInventoryIncremented;
  final Function(String) onProductInventoryDecremented;
  final VoidCallback? onLongPress;
  final VoidCallback? onAddToCart;

  const ProductTile({
    super.key,
    required this.product,
    this.specifyDimensions = false,
    required this.productTileType,
    required this.isProductSelected,
    required this.onProductClicked,
    required this.onProductInventoryIncremented,
    required this.onProductInventoryDecremented,
    this.onLongPress,
    this.onAddToCart,
  });

  @override
  State<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  int cartCount = 0; // Local cart count state

  bool get isRecentProduct => DateTime.now()
      .subtract(const Duration(days: 1))
      .isAfter(widget.product.createdAt ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    _syncWithCartBloc();
  }

  void _syncWithCartBloc() {
    try {
      final cartState = context.read<CartBloc>().state;
      if (cartState is CartLoaded) {
        final cartItem = cartState.items.firstWhere(
          (item) => item.id == widget.product.id,
          orElse: () => CartItem(
            id: widget.product.id,
            product: widget.product,
            quantity: 0,
            agentId: '',
            agentName: '',
          ),
        );
        if (cartItem.quantity != cartCount) {
          setState(() {
            cartCount = cartItem.quantity;
          });
        }
      }
    } catch (e) {
      // CartBloc not available, keep local state
    }
  }

  Widget _buildProductImage() {
    if (widget.product.imageUrl != null &&
        widget.product.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.product.imageUrl!.split(',').first,
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No image',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _incrementCart() {
    if (cartCount < widget.product.stockQuantity) {
      setState(() {
        cartCount++;
      });
      widget.onProductInventoryIncremented(widget.product.id);
      if (widget.onAddToCart != null) {
        widget.onAddToCart!();
      }
    }
  }

  void _decrementCart() {
    if (cartCount > 0) {
      setState(() {
        cartCount--;
      });
      widget.onProductInventoryDecremented(widget.product.id);
    }
  }

  Widget _buildCartControls() {
    if (cartCount == 0) {
      return GestureDetector(
        onTap: widget.product.stockQuantity > 0
            ? (widget.onAddToCart ?? _incrementCart)
            : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(8),
              topLeft: Radius.circular(8),
            ),
          ),
          child: const Icon(Icons.add, size: 18, color: Colors.white),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(8),
            topLeft: Radius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                try {
                  if (cartCount > 1) {
                    context.read<CartBloc>().add(
                      UpdateCartItemQuantityEvent(
                        productId: widget.product.id,
                        quantity: cartCount - 1,
                      ),
                    );
                  } else {
                    context.read<CartBloc>().add(
                      RemoveFromCartEvent(widget.product.id),
                    );
                  }
                } catch (e) {
                  // CartBloc not available, use local state
                  _decrementCart();
                }
              },
              child: const Icon(Icons.remove, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              '$cartCount',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: cartCount < widget.product.stockQuantity
                  ? () {
                      try {
                        context.read<CartBloc>().add(
                          UpdateCartItemQuantityEvent(
                            productId: widget.product.id,
                            quantity: cartCount + 1,
                          ),
                        );
                      } catch (e) {
                        // CartBloc not available, use local state
                        _incrementCart();
                      }
                    }
                  : null,
              child: Icon(
                Icons.add,
                size: 16,
                color: cartCount >= widget.product.stockQuantity
                    ? Colors.grey
                    : Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onProductClicked(widget.product.id),
      onLongPress: widget.onLongPress,
      child: Container(
        height: widget.specifyDimensions ? 140.0 : 120,
        width: widget.specifyDimensions ? 200.0 : 180,
        child: Card(
          color: Colors.white,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.isProductSelected
                ? const BorderSide(color: Colors.black, width: 1)
                : BorderSide.none,
          ),
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Product Image
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: _buildProductImage(),
                    ),
                  ),

                  // Product Info
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 6),
                          // Product Name
                          Text(
                            widget.product.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6),
                          // Price with strikethrough
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '\$${widget.product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 15,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text:
                                      '\$${(widget.product.price + 21.00).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF637087),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Stock Status Badge
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.product.stockQuantity > 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.product.stockQuantity > 0
                          ? Colors.green
                          : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.product.stockQuantity > 0
                        ? 'Stock: ${widget.product.stockQuantity}'
                        : 'Out of Stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.product.stockQuantity > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Cart Controls - Always show for all products
              Positioned(
                right: 0,
                bottom: 0,
                child: Builder(
                  builder: (context) {
                    try {
                      return BlocBuilder<CartBloc, CartState>(
                        builder: (context, cartState) {
                          _syncWithCartBloc();
                          return _buildCartControls();
                        },
                      );
                    } catch (e) {
                      // CartBloc not available, use local state
                      return _buildCartControls();
                    }
                  },
                ),
              ),

              // NEW/Discount Badge
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: isRecentProduct ? Colors.black : Colors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 1,
                    horizontal: 3,
                  ),
                  child: Text(
                    isRecentProduct ? 'NEW' : '20%',
                    style: TextStyle(
                      fontSize: 10,
                      color: isRecentProduct ? Colors.white : Colors.black54,
                    ),
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
