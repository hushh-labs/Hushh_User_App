import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/agent_product_model.dart';
import '../bloc/cart_bloc.dart';

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

    return Scaffold(
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
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
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
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
    );
  }
}


