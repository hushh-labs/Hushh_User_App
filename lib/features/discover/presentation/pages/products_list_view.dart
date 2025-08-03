import 'package:flutter/material.dart';
import '../../data/models/agent_product_model.dart';
import '../../domain/entities/enums.dart';
import '../widgets/product_tile.dart';

class ProductsListView extends StatefulWidget {
  final List<AgentProductModel> products;
  final bool shouldSelectProducts;
  final Function(AgentProductModel) onDelete;
  final bool shouldDismiss;

  const ProductsListView({
    super.key,
    required this.products,
    this.shouldSelectProducts = false,
    required this.onDelete,
    required this.shouldDismiss,
  });

  @override
  State<ProductsListView> createState() => _ProductsListViewState();
}

class _ProductsListViewState extends State<ProductsListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.products.length,
      itemBuilder: (context, index) {
        final product = widget.products[index];
        return Dismissible(
          key: Key(product.id),
          direction: widget.shouldDismiss
              ? DismissDirection.endToStart
              : DismissDirection.none,
          onDismissed: (direction) {
            widget.onDelete(product);
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              final value = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Product'),
                  content: const Text(
                    'Are you sure you want to delete this product?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              return value ?? false;
            }
            return false;
          },
          background: Container(
            color: Colors.red,
            child: const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Icon(Icons.delete_outline, color: Colors.white),
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ProductTile(
              product: product,
              specifyDimensions: true,
              productTileType: ProductTileType.viewProducts,
              isProductSelected: false,
              onProductClicked: (productId) {
                // Handle product click
              },
              onProductInventoryIncremented: (productId) {
                // Handle increment
              },
              onProductInventoryDecremented: (productId) {
                // Handle decrement
              },
            ),
          ),
        );
      },
    );
  }
}
