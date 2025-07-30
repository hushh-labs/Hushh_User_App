import 'package:flutter/material.dart';

// Simple mock lookbook model
class MockLookBook {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final String createdAt;
  final int numberOfProducts;

  const MockLookBook({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.createdAt,
    this.numberOfProducts = 0,
  });
}

class LookBooksListView extends StatelessWidget {
  final List<MockLookBook> lookbooks;
  final bool fromChat;
  final bool sendLookBook;

  const LookBooksListView({
    super.key,
    required this.lookbooks,
    this.fromChat = false,
    this.sendLookBook = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: fromChat ? const NeverScrollableScrollPhysics() : null,
      itemCount: lookbooks.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: fromChat ? 1 : 2,
        childAspectRatio: fromChat ? 1 : .7,
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
                    content: Text('Opening lookbook: ${lookbook.name}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lookbook preview grid
                      Expanded(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                          itemCount: 4,
                          itemBuilder: (context, gridIndex) {
                            if (gridIndex == 3 &&
                                lookbook.numberOfProducts > 4) {
                              // Show "+N" for additional products
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${lookbook.numberOfProducts - 3}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Show product image or placeholder
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                                image: gridIndex < lookbook.images.length
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          lookbook.images[gridIndex],
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: gridIndex >= lookbook.images.length
                                  ? const Icon(Icons.image, color: Colors.grey)
                                  : null,
                            );
                          },
                        ),
                      ),
                      // Lookbook info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          lookbook.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "Last updated: ${lookbook.createdAt}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF637087),
                          ),
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
