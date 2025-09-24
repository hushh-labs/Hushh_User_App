class AgentProductRevamp {
  // Core
  final String id;
  final String? sku;
  final String agentId;
  final String brand;
  final String name;
  final String? subtitle;

  // Content
  final String shortDescription;
  final String longDescription;
  final List<String> highlights;

  // Media
  final List<String> imageUrls; // first is primary
  final List<String>? videoUrls;

  // Pricing
  final double price;
  final String currency;
  final double? mrp;
  final double? discountPercent;
  final DateTime? priceEffectiveFrom;
  final DateTime? priceEffectiveTo;

  // Inventory
  final int stockQuantity;
  final String availability; // in_stock | out_of_stock | preorder
  final int? minOrderQty;
  final int? maxOrderQty;

  // Attributes/specs
  final Map<String, String> attributes; // e.g. Material, Dimensions, etc.

  // Classification
  final List<String> categories;
  final List<String> tags;

  // Reviews summary
  final double rating; // 0..5
  final int reviewCount;

  // Relations
  final List<String>? lookbookIds;
  final List<String>? relatedProductIds;

  // Audit
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const AgentProductRevamp({
    // Core
    required this.id,
    this.sku,
    required this.agentId,
    required this.brand,
    required this.name,
    this.subtitle,
    // Content
    required this.shortDescription,
    required this.longDescription,
    this.highlights = const [],
    // Media
    this.imageUrls = const [],
    this.videoUrls,
    // Pricing
    required this.price,
    this.currency = 'INR',
    this.mrp,
    this.discountPercent,
    this.priceEffectiveFrom,
    this.priceEffectiveTo,
    // Inventory
    this.stockQuantity = 0,
    this.availability = 'in_stock',
    this.minOrderQty,
    this.maxOrderQty,
    // Attributes/specs
    this.attributes = const {},
    // Classification
    this.categories = const [],
    this.tags = const [],
    // Reviews
    this.rating = 0,
    this.reviewCount = 0,
    // Relations
    this.lookbookIds,
    this.relatedProductIds,
    // Audit
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });
}
