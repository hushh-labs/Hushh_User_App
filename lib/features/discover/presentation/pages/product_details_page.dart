import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/agent_product_model.dart';
import '../bloc/cart_bloc.dart';
import '../services/discover_dialog_service.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart' as chat;
import '../../../chat/presentation/pages/regular_chat_page.dart';
import '../../../chat/domain/entities/chat_entity.dart';

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;
  final String agentId;
  final String agentName;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.agentId,
    required this.agentName,
  });

  AgentProductModel _toModel(Map<String, dynamic> p) {
    return AgentProductModel(
      id: p['id']?.toString() ?? '',
      productName: p['name']?.toString() ?? '',
      productDescription: p['productDescription']?.toString(),
      productPrice: (p['price'] as num?)?.toDouble() ?? 0.0,
      productImage: p['imageUrl']?.toString(),
      stockQuantity: (p['stock'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _toModel(product);
    final images = (product['imageUrl']?.toString() ?? '')
        .split(',')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartAgentConflict) {
          DiscoverDialogService.showCartConflictDialog(context, state);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(model.productName.isEmpty ? 'Product' : model.productName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Images carousel (simple PageView)
          AspectRatio(
            aspectRatio: 1,
            child: PageView.builder(
              itemCount: images.isNotEmpty ? images.length : 1,
              itemBuilder: (context, index) {
                final url = images.isNotEmpty ? images[index] : null;
                if (url == null) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 48),
                    ),
                  );
                }
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48),
                    ),
                  ),
                );
              },
            ),
          ),

          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.productName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: '\$',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA342FF),
                          ),
                        ),
                        TextSpan(
                          text: model.productPrice.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA342FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if ((model.productDescription ?? '').trim().isNotEmpty)
                    Text(
                      model.productDescription!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Left: Add to Cart or Quantity Controls (mirrors product tile behavior)
              Expanded(
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
                    int currentQty = 0;
                    if (cartState is CartLoaded) {
                      final existing = cartState.items.firstWhere(
                        (i) => i.id == model.id,
                        orElse: () => CartItem(
                          id: model.id,
                          product: model,
                          quantity: 0,
                          agentId: '',
                          agentName: '',
                        ),
                      );
                      currentQty = existing.quantity;
                    }

                    if (currentQty == 0) {
                      final isOutOfStock = model.stockQuantity <= 0;
                      return ElevatedButton.icon(
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                final m = _toModel(product);
                                try {
                                  context.read<CartBloc>().add(
                                        AddToCartEvent(
                                          product: m,
                                          agentId: agentId,
                                          agentName: agentName,
                                        ),
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cart unavailable'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        label:
                            Text(isOutOfStock ? 'Out of Stock' : 'Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }

                    // Quantity controls when already in cart
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              try {
                                if (currentQty > 1) {
                                  context.read<CartBloc>().add(
                                        UpdateCartItemQuantityEvent(
                                          productId: model.id,
                                          quantity: currentQty - 1,
                                        ),
                                      );
                                } else {
                                  context
                                      .read<CartBloc>()
                                      .add(RemoveFromCartEvent(model.id));
                                }
                              } catch (e) {
                                // no-op if bloc not available
                              }
                            },
                            child: const Icon(
                              Icons.remove,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$currentQty',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: currentQty < model.stockQuantity
                                ? () {
                                    try {
                                      context.read<CartBloc>().add(
                                            UpdateCartItemQuantityEvent(
                                              productId: model.id,
                                              quantity: currentQty + 1,
                                            ),
                                          );
                                    } catch (e) {
                                      // no-op if bloc not available
                                    }
                                  }
                                : null,
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: currentQty < model.stockQuantity
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Right: Chat button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _handleProductChat(context);
                  },
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _handleProductChat(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to start a chat'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (agentId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final participantIds = [currentUser.uid, agentId]..sort();
      final chatId = participantIds.join('_');

      final chatBloc = chat.ChatBloc();
      chatBloc.add(chat.OpenChatEvent(chatId));

      // Send a quick product inquiry message
      final productName = product['name']?.toString() ?? 'Product';
      final productPrice = (product['price'] as num?)?.toDouble() ?? 0.0;
      final productImage = product['imageUrl']?.toString();
      final productSku = product['id']?.toString() ?? 'N/A';

      await Future.delayed(const Duration(milliseconds: 600));
      final inquiryMessage =
          'Hi! I\'m interested in ${productName} (SKU: ${productSku}) priced at \$${productPrice.toStringAsFixed(2)}.';
      chatBloc.add(chat.SendMessageEvent(
        chatId: chatId,
        message: inquiryMessage,
        isBot: false,
      ));

      if (productImage != null && productImage.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        chatBloc.add(
          chat.SendMessageEvent(
            chatId: chatId,
            message: 'Product Image',
            isBot: false,
            messageType: MessageType.image,
            imageUrl: productImage,
          ),
        );
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: chatBloc,
            child: RegularChatPage(
              chatId: chatId,
              userName: agentName,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


