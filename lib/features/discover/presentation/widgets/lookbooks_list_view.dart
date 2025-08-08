import 'package:flutter/material.dart';
import '../../data/models/lookbook_model.dart';
import '../../data/models/agent_product_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class LookBooksListView extends StatelessWidget {
  final List<LookbookModel> lookbooks;
  final bool fromChat;
  final bool sendLookBook;
  final List<AgentProductModel>? products;

  const LookBooksListView({
    super.key,
    required this.lookbooks,
    this.fromChat = false,
    this.sendLookBook = false,
    this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (lookbooks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Lookbooks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No lookbooks available yet',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: fromChat ? const NeverScrollableScrollPhysics() : null,
      itemCount: lookbooks.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: fromChat ? 1 : 2,
        childAspectRatio: fromChat ? 1 : 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final lookbook = lookbooks[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening lookbook: ${lookbook.lookbookName}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  height: 260,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lookbook preview grid
                      SizedBox(
                        height: 160,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: 4,
                          itemBuilder: (context, gridIndex) {
                            // Get product images for this lookbook
                            final lookbookProducts =
                                products
                                    ?.where(
                                      (product) => lookbook.products.contains(
                                        product.id,
                                      ),
                                    )
                                    .toList() ??
                                [];

                            if (gridIndex == 3 && lookbookProducts.length > 4) {
                              // Show "+N" for additional products
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFeaeff3),
                                  borderRadius: BorderRadius.circular(8),
                                  image: lookbookProducts.length > 3
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            lookbookProducts[3].productImage ??
                                                '',
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "+${lookbookProducts.length - 3}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Show product image if available
                            if (gridIndex < lookbookProducts.length) {
                              final product = lookbookProducts[gridIndex];
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFeaeff3),
                                  borderRadius: BorderRadius.circular(8),
                                  image: product.productImage != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            product.productImage!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: product.productImage == null
                                    ? const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      )
                                    : null,
                              );
                            }

                            // Show empty placeholder
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFeaeff3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Lookbook info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              lookbook.lookbookName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Last updated: ${timeago.format(lookbook.createdAt)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF637087),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
