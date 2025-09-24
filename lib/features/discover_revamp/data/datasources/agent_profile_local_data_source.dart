import '../../domain/entities/agent_product_revamp.dart';
import '../../domain/entities/lookbook_revamp.dart';

abstract class AgentProfileLocalDataSource {
  Future<List<AgentProductRevamp>> getProducts(String agentId);
  Future<List<LookbookRevamp>> getLookbooks(String agentId);
}

class AgentProfileLocalDataSourceImpl implements AgentProfileLocalDataSource {
  @override
  Future<List<AgentProductRevamp>> getProducts(String agentId) async {
    // Dummy mocked products
    final now = DateTime.now();
    return [
      AgentProductRevamp(
        id: 'p1',
        sku: 'SKU-001',
        agentId: agentId,
        brand: 'Demo Brand',
        name: 'Monogram Tote',
        subtitle: 'PM, Brown',
        shortDescription: 'Iconic monogram tote.',
        longDescription: 'Crafted in coated canvas with leather trims...',
        highlights: const ['Authentic', 'Free shipping', '30-day return'],
        imageUrls: const [],
        price: 2499.0,
        currency: 'INR',
        mrp: 2799.0,
        discountPercent: 10.7,
        stockQuantity: 8,
        availability: 'in_stock',
        attributes: const {
          'Material': 'Coated canvas, leather',
          'Dimensions': '20×15×8 cm',
        },
        categories: const ['bags', 'luxury'],
        tags: const ['new', 'women'],
        rating: 4.6,
        reviewCount: 128,
        lookbookIds: const ['lb1'],
        createdAt: now,
        updatedAt: now,
        publishedAt: now,
      ),
      AgentProductRevamp(
        id: 'p2',
        sku: 'SKU-002',
        agentId: agentId,
        brand: 'Demo Brand',
        name: 'Classic Watch',
        subtitle: 'Automatic',
        shortDescription: 'Automatic chronograph.',
        longDescription: 'Swiss movement, sapphire crystal...',
        highlights: const ['2-year warranty'],
        imageUrls: const [],
        price: 5499.0,
        currency: 'INR',
        stockQuantity: 3,
        availability: 'in_stock',
        attributes: const {'Material': 'Steel', 'Dimensions': '42mm'},
        categories: const ['watches'],
        tags: const ['men'],
        rating: 4.2,
        reviewCount: 42,
        lookbookIds: const ['lb1'],
        createdAt: now,
        updatedAt: now,
        publishedAt: now,
      ),
      AgentProductRevamp(
        id: 'p3',
        sku: 'SKU-003',
        agentId: agentId,
        brand: 'Demo Brand',
        name: 'Sunglasses',
        subtitle: 'UV 400',
        shortDescription: 'UV protected shades.',
        longDescription: 'Polarized lenses with lightweight frame.',
        highlights: const ['Polarized'],
        imageUrls: const [],
        price: 399.0,
        currency: 'INR',
        stockQuantity: 20,
        availability: 'in_stock',
        attributes: const {'Material': 'Acetate', 'Dimensions': 'Standard'},
        categories: const ['accessories'],
        tags: const ['unisex'],
        rating: 4.0,
        reviewCount: 12,
        lookbookIds: const ['lb1'],
        createdAt: now,
        updatedAt: now,
        publishedAt: now,
      ),
    ];
  }

  @override
  Future<List<LookbookRevamp>> getLookbooks(String agentId) async {
    // Dummy mocked lookbooks
    return [
      LookbookRevamp(
        id: 'lb1',
        name: 'Summer Picks',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        productIds: const ['p1', 'p2', 'p3'],
      ),
    ];
  }
}
