import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class LookbookRevampModel {
  final String lookbookName;
  final DateTime createdAt;
  final List<String> products;

  LookbookRevampModel({
    required this.lookbookName,
    required this.createdAt,
    required this.products,
  });
}

class AgentProductRevampModel {
  final String id;
  final String? productImage;

  AgentProductRevampModel({required this.id, this.productImage});
}

class LookBooksListView extends StatelessWidget {
  final List<LookbookRevampModel> lookbooks;
  final bool fromChat;
  final bool sendLookBook;
  final List<AgentProductRevampModel>? products;

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
      padding: const EdgeInsets.only(top: 4),
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
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: 260,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const double spacing = 6;
                            final double tileSize =
                                (constraints.maxWidth - spacing) / 2;

                            Widget buildTile(int idx) {
                              final lookbookProducts =
                                  products
                                      ?.where(
                                        (p) => lookbook.products.contains(p.id),
                                      )
                                      .toList() ??
                                  [];
                              if (idx == 3 && lookbookProducts.length > 4) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: tileSize,
                                      height: tileSize,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(8),
                                        image: lookbookProducts.length > 3
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  lookbookProducts[3]
                                                          .productImage ??
                                                      '',
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                    ),
                                    Container(
                                      width: tileSize,
                                      height: tileSize,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "+${lookbookProducts.length - 3}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              if (idx < lookbookProducts.length) {
                                final product = lookbookProducts[idx];
                                return Container(
                                  width: tileSize,
                                  height: tileSize,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
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

                              return Container(
                                width: tileSize,
                                height: tileSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              );
                            }

                            return SizedBox(
                              height: tileSize * 2 + spacing,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      buildTile(0),
                                      const SizedBox(width: spacing),
                                      buildTile(1),
                                    ],
                                  ),
                                  const SizedBox(height: spacing),
                                  Row(
                                    children: [
                                      buildTile(2),
                                      const SizedBox(width: spacing),
                                      buildTile(3),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Flexible(
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
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
            ),
          ],
        );
      },
    );
  }
}
