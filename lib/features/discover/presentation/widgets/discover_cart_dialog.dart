import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/cart_bloc.dart';
import '../../data/models/agent_product_model.dart';
import '../pages/order_confirmation_page.dart';

class DiscoverCartDialog extends StatelessWidget {
  final CartBloc cartBloc;

  const DiscoverCartDialog({super.key, required this.cartBloc});

  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color borderColor = Color(0xFFE0E0E0);

  void _showCartConflictDialog(BuildContext context, CartAgentConflict state) {
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cartBloc,
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is CartLoaded && cartState.items.isNotEmpty) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'HUSHHCOINS',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
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
                                      child: const Icon(Icons.remove, size: 16),
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
                                      child: const Icon(Icons.add, size: 16),
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
                            String agentPhone = '+91';
                            String customerPhone = '+91';
                            String customerName = 'Customer';

                            // Get current user's profile information
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser != null) {
                              customerPhone = currentUser.phoneNumber ?? '+91';
                              customerName =
                                  currentUser.displayName ?? 'Customer';

                              debugPrint(
                                'Firebase Auth displayName: ${currentUser.displayName}',
                              );
                              debugPrint(
                                'Firebase Auth phoneNumber: ${currentUser.phoneNumber}',
                              );

                              // Get user profile from Firestore
                              try {
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('HushUsers')
                                    .doc(currentUser.uid)
                                    .get();

                                if (userDoc.exists) {
                                  final userData = userDoc.data()!;
                                  customerPhone =
                                      userData['phoneNumber'] ?? customerPhone;
                                  customerName =
                                      userData['fullname'] ??
                                      userData['fullName'] ??
                                      userData['name'] ??
                                      customerName;

                                  debugPrint('Firestore userData: $userData');
                                  debugPrint(
                                    'Firestore fullname: ${userData['fullname']}',
                                  );
                                  debugPrint(
                                    'Firestore fullName: ${userData['fullName']}',
                                  );
                                  debugPrint(
                                    'Firestore name: ${userData['name']}',
                                  );
                                  debugPrint(
                                    'Firestore phoneNumber: ${userData['phoneNumber']}',
                                  );
                                } else {
                                  debugPrint(
                                    'User document does not exist in HushhUsers collection',
                                  );
                                }
                              } catch (e) {
                                debugPrint('Error fetching user profile: $e');
                              }
                            }

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
                                      agentData['brandName'] ?? 'Unknown Brand';
                                  agentPhone = agentData['phone'] ?? '+91';
                                }
                              } catch (e) {
                                debugPrint('Error fetching agent details: $e');
                              }
                            }

                            // Close modal and navigate in one go
                            Navigator.pop(context);

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
                                    value: cartBloc,
                                    child: OrderConfirmationPage(
                                      cartItems: cartState.items,
                                      agentName: agentName,
                                      brandName: brandName,
                                      totalPrice: cartState.totalPrice,
                                      agentPhone: customerPhone,
                                      customerName: customerName,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(child: Text('Cart is empty')),
            );
          }
        },
      ),
    );
  }
}
