import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushh_user_app/features/discover/data/models/agent_product_model.dart';
import 'package:hushh_user_app/features/discover/domain/entities/enums.dart';
import 'package:hushh_user_app/features/discover/presentation/bloc/inventory_bloc.dart';
import 'package:hushh_user_app/features/discover/presentation/widgets/product_tile.dart';
import 'package:hushh_user_app/shared/di/dependencies.dart';

class ProductsGridView extends StatefulWidget {
  final List<AgentProductModel> products;
  final ProductTileType productTileType;
  final bool shouldSelectProducts;
  final Function(AgentProductModel)? onDelete;
  final bool shouldDismiss;

  const ProductsGridView({
    super.key,
    required this.products,
    required this.productTileType,
    this.shouldSelectProducts = false,
    this.onDelete,
    this.shouldDismiss = false,
  });

  @override
  State<ProductsGridView> createState() => _ProductsGridViewState();
}

class _ProductsGridViewState extends State<ProductsGridView> {
  Set<String> selectedProducts = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      bloc: sl<InventoryBloc>(),
      builder: (context, state) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 items per row
            crossAxisSpacing: 12, // Horizontal spacing between items
            mainAxisSpacing: 16, // Vertical spacing between items
            childAspectRatio: 0.85, // Width/Height ratio (more square-like)
          ),
          itemCount: widget.products.length,
          itemBuilder: (context, index) {
            final product = widget.products[index];
            final isSelected = selectedProducts.contains(product.id);

            Widget productTile = ProductTile(
              specifyDimensions: false, // Let GridView handle dimensions
              onProductClicked: (productId) {
                if (widget.shouldSelectProducts) {
                  setState(() {
                    if (selectedProducts.contains(productId)) {
                      selectedProducts.remove(productId);
                    } else {
                      selectedProducts.add(productId);
                    }
                  });
                } else {
                  // Handle product click (navigate to product details, etc.)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening ${product.productName}...'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              onProductInventoryIncremented: (productId) {
                sl<InventoryBloc>().add(
                  UpdateProductStockQuantityEvent(
                    productId: productId,
                    newQuantity: product.stockQuantity + 1,
                  ),
                );
              },
              onProductInventoryDecremented: (productId) {
                sl<InventoryBloc>().add(
                  UpdateProductStockQuantityEvent(
                    productId: productId,
                    newQuantity: product.stockQuantity - 1,
                  ),
                );
              },
              isProductSelected: isSelected,
              productTileType: widget.productTileType,
              product: product,
            );

            // Add dismissible wrapper if needed
            if (widget.shouldDismiss && widget.onDelete != null) {
              return Dismissible(
                key: Key(product.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  widget.onDelete!(product);
                },
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await _showDeleteConfirmation(context, product);
                  }
                  return false;
                },
                child: productTile,
              );
            }

            return productTile;
          },
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    AgentProductModel product,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DeleteProductBottomSheet(
          productName: product.productName,
          onCancel: () => Navigator.pop(context, false),
          onDelete: () => Navigator.pop(context, true),
        );
      },
    );
    return result ?? false;
  }
}

class _DeleteProductBottomSheet extends StatelessWidget {
  final String productName;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _DeleteProductBottomSheet({
    required this.productName,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Delete Product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "$productName"? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative: If you want to keep your existing horizontal view but make it wrap
class ProductsWrapView extends StatefulWidget {
  final List<AgentProductModel> products;
  final ProductTileType productTileType;

  const ProductsWrapView({
    super.key,
    required this.products,
    required this.productTileType,
  });

  @override
  State<ProductsWrapView> createState() => _ProductsWrapViewState();
}

class _ProductsWrapViewState extends State<ProductsWrapView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      bloc: sl<InventoryBloc>(),
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12, // Horizontal spacing
            runSpacing: 16, // Vertical spacing
            children: widget.products.map((product) {
              return SizedBox(
                width:
                    (MediaQuery.of(context).size.width - 44) /
                    2, // 2 items per row
                child: ProductTile(
                  specifyDimensions: true,
                  onProductClicked: (productId) {},
                  onProductInventoryIncremented: (productId) {
                    sl<InventoryBloc>().add(
                      UpdateProductStockQuantityEvent(
                        productId: productId,
                        newQuantity: product.stockQuantity + 1,
                      ),
                    );
                  },
                  onProductInventoryDecremented: (productId) {
                    sl<InventoryBloc>().add(
                      UpdateProductStockQuantityEvent(
                        productId: productId,
                        newQuantity: product.stockQuantity - 1,
                      ),
                    );
                  },
                  isProductSelected: false,
                  productTileType: widget.productTileType,
                  product: product,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
