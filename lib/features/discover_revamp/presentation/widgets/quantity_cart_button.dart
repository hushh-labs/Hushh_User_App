import 'package:flutter/material.dart';
import '../services/cart_presentation_service.dart';
import '../../domain/entities/cart_entity.dart';

/// Quantity-aware cart button that shows +/- controls after adding to cart
/// Matches the original design behavior
class QuantityCartButton extends StatefulWidget {
  final String? productId;
  final String productName;
  final String agentId;
  final String agentName;
  final double price;
  final String? imageUrl;
  final String? description;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const QuantityCartButton({
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
  State<QuantityCartButton> createState() => _QuantityCartButtonState();
}

class _QuantityCartButtonState extends State<QuantityCartButton> {
  final CartPresentationService _cartService = CartPresentationService();
  bool _isLoading = false;

  @override
  void dispose() {
    _cartService.dispose();
    super.dispose();
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
      quantity: 1,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        widget.onSuccess?.call();
        _showBlackToast(result.message);
      } else if (result.requiresConfirmation) {
        _showConfirmationDialog(result);
      } else if (result.isInfo) {
        _showBlackToast(result.message);
      } else {
        widget.onError?.call();
        _showBlackToast(result.message);
      }
    }
  }

  Future<void> _updateQuantity(int newQuantity) async {
    if (widget.productId == null) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _cartService.updateQuantity(
      widget.productId!,
      widget.productName,
      newQuantity,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        _showBlackToast(result.message);
      } else {
        _showBlackToast(result.message);
      }
    }
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
                    widget.onSuccess?.call();
                    _showBlackToast(confirmResult.message);
                  } else {
                    widget.onError?.call();
                    _showBlackToast(confirmResult.message);
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
        int currentQuantity = 0;
        if (snapshot.hasData && widget.productId != null) {
          try {
            final cartItem = snapshot.data!.items.firstWhere(
              (item) => item.productId == widget.productId,
            );
            currentQuantity = cartItem.quantity;
          } catch (e) {
            // Item not found in cart, quantity remains 0
            currentQuantity = 0;
          }
        }

        if (currentQuantity == 0) {
          // Show "Add to Cart" button
          return Container(
            height: 48,
            constraints: const BoxConstraints(minWidth: 120),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isLoading ? null : _addToCart,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_shopping_cart_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Add to Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        } else {
          // Show quantity controls
          return Container(
            height: 48,
            constraints: const BoxConstraints(minWidth: 120),
            child: Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Minus button
                        GestureDetector(
                          onTap: () {
                            if (currentQuantity > 0) {
                              _updateQuantity(currentQuantity - 1);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),

                        // Quantity display
                        Expanded(
                          child: Center(
                            child: Text(
                              currentQuantity.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        // Plus button
                        GestureDetector(
                          onTap: () {
                            _updateQuantity(currentQuantity + 1);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }
      },
    );
  }
}
