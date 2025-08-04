import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../../data/models/agent_product_model.dart';

class DiscoverDialogService {
  static const Color primaryPurple = Color(0xFFA342FF);

  static void showCartConflictDialog(
    BuildContext context,
    CartAgentConflict state,
  ) {
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
                _handleCartConflictResolution(context, state);
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

  static void _handleCartConflictResolution(
    BuildContext context,
    CartAgentConflict state,
  ) {
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
        content: Text('Cart cleared and ${state.product.productName} added!'),
        backgroundColor: primaryPurple,
      ),
    );
  }
}
