import 'package:flutter/material.dart';
import '../services/cart_presentation_service.dart';
import '../../domain/entities/cart_entity.dart';

/// Cart icon widget with badge showing item count
/// Listens to cart changes for real-time updates
class CartIconWithBadge extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;
  final Color? badgeColor;
  final Color? badgeTextColor;

  const CartIconWithBadge({
    super.key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24.0,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  State<CartIconWithBadge> createState() => _CartIconWithBadgeState();
}

class _CartIconWithBadgeState extends State<CartIconWithBadge> {
  final CartPresentationService _cartService = CartPresentationService();
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _listenToCartChanges();
  }

  @override
  void dispose() {
    _cartService.dispose();
    super.dispose();
  }

  void _loadCartCount() async {
    final count = await _cartService.getCartCount();
    if (mounted) {
      setState(() {
        _cartCount = count;
      });
    }
  }

  void _listenToCartChanges() {
    _cartService.cartStream.listen((cart) {
      if (mounted) {
        setState(() {
          _cartCount = cart.itemCount;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: widget.iconColor ?? Colors.grey[700],
            size: widget.iconSize,
          ),
          if (_cartCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                decoration: BoxDecoration(
                  color: widget.badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    _cartCount > 99 ? '99+' : _cartCount.toString(),
                    style: TextStyle(
                      color: widget.badgeTextColor ?? Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated cart icon that shows add animation
class AnimatedCartIcon extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;

  const AnimatedCartIcon({
    super.key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24.0,
  });

  @override
  State<AnimatedCartIcon> createState() => _AnimatedCartIconState();
}

class _AnimatedCartIconState extends State<AnimatedCartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animate() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _animate();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              Icons.shopping_cart_outlined,
              color: widget.iconColor ?? Colors.grey[700],
              size: widget.iconSize,
            ),
          );
        },
      ),
    );
  }
}

/// Simple cart button with loading state
class CartButton extends StatefulWidget {
  final String? productId;
  final String productName;
  final String agentId;
  final String agentName;
  final double price;
  final String? imageUrl;
  final String? description;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const CartButton({
    super.key,
    this.productId,
    required this.productName,
    required this.agentId,
    required this.agentName,
    required this.price,
    this.imageUrl,
    this.description,
    this.onSuccess,
    this.onError,
  });

  @override
  State<CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<CartButton> {
  final CartPresentationService _cartService = CartPresentationService();
  bool _isLoading = false;
  bool _isInCart = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _checkCartStatus();
    }
  }

  @override
  void dispose() {
    _cartService.dispose();
    super.dispose();
  }

  Future<void> _checkCartStatus() async {
    if (widget.productId != null) {
      final isInCart = await _cartService.isProductInCart(widget.productId!);
      if (mounted) {
        setState(() {
          _isInCart = isInCart;
        });
      }
    }
  }

  Future<void> _addToCart() async {
    if (widget.productId == null) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _cartService.addToCart(
      productId: widget.productId!,
      productName: widget.productName,
      agentId: widget.agentId,
      agentName: widget.agentName,
      price: widget.price,
      imageUrl: widget.imageUrl,
      description: widget.description,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        setState(() {
          _isInCart = true;
        });
        widget.onSuccess?.call();
        _showSuccessMessage(result.message);
      } else if (result.requiresConfirmation) {
        _showConfirmationDialog(result);
      } else if (result.isInfo) {
        _showInfoMessage(result.message);
      } else {
        widget.onError?.call();
        _showErrorMessage(result.message);
      }
    }
  }

  void _showSuccessMessage(String message) {
    _showBlackToast(message);
  }

  void _showInfoMessage(String message) {
    _showBlackToast(message);
  }

  void _showErrorMessage(String message) {
    _showBlackToast(message);
  }

  void _showBlackToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showConfirmationDialog(CartActionResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Replace Cart Items?'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = true;
                });

                final confirmResult = await _cartService.confirmAgentSwitch(
                  result.actionData!,
                );

                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });

                  if (confirmResult.isSuccess) {
                    setState(() {
                      _isInCart = true;
                    });
                    widget.onSuccess?.call();
                    _showSuccessMessage(confirmResult.message);
                  } else {
                    widget.onError?.call();
                    _showErrorMessage(confirmResult.message);
                  }
                }
              },
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CartEntity>(
      stream: _cartService.cartStream,
      builder: (context, snapshot) {
        bool productInCart = false;
        if (snapshot.hasData && widget.productId != null) {
          productInCart = snapshot.data!.items.any(
            (item) => item.productId == widget.productId,
          );
        }

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isLoading ? null : _addToCart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: productInCart ? Colors.green : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        productInCart
                            ? Icons.check_circle_outline
                            : Icons.add_shopping_cart_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        productInCart ? 'In Cart' : 'Add to Cart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
