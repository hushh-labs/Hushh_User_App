import 'package:flutter/material.dart';
import '../widgets/quantity_cart_button.dart';

class ProductRevampPage extends StatefulWidget {
  final String productName;
  final String brand;
  final String? subtitle;
  final String description;
  final String longDescription;
  final List<String> imageUrls;
  final double price;
  final List<String>? highlights;
  final double rating;
  final int reviewCount;
  // Extended optional product fields
  final Map<String, String>? attributes; // e.g., Display, Chip, Camera
  final List<String>? categories;
  final List<String>? tags;
  final String? sku;
  final String? availability;
  final int? stockQuantity;
  final String? currency; // e.g., USD, ₹, etc.
  final double? mrp;
  final double? discountPercent;
  final List<String>? videoUrls;
  final List<String>? relatedProductIds;
  // Legacy extras kept for compatibility if passed
  final String? material;
  final String? dimensions;
  // Cart functionality requires agent information
  final String? agentId;
  final String? agentName;
  final String? productId;

  const ProductRevampPage({
    super.key,
    required this.productName,
    required this.brand,
    required this.description,
    required this.longDescription,
    required this.imageUrls,
    required this.price,
    this.subtitle,
    this.highlights,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.attributes,
    this.categories,
    this.tags,
    this.sku,
    this.availability,
    this.stockQuantity,
    this.currency,
    this.mrp,
    this.discountPercent,
    this.videoUrls,
    this.relatedProductIds,
    this.material,
    this.dimensions,
    this.agentId,
    this.agentName,
    this.productId,
  });

  @override
  State<ProductRevampPage> createState() => _ProductRevampPageState();
}

class _ProductRevampPageState extends State<ProductRevampPage>
    with TickerProviderStateMixin {
  int _index = 0;
  int _quantity = 0;
  late final PageController _pageController;
  late final TabController _tabController;
  int _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.removeListener(() {});
    _reviewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool _hasHighlights = (widget.highlights ?? const []).isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          widget.productName,
          style: const TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image gallery
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: widget.imageUrls.length,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (context, i) => Image.network(
                          widget.imageUrls[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Vertical thumbnail rail (left)
                      if (widget.imageUrls.length > 1)
                        Positioned(
                          left: 8,
                          top: 8,
                          bottom: 8,
                          child: SizedBox(
                            width: 56,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(0),
                              itemCount: widget.imageUrls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, i) {
                                final isActive = i == _index;
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      i,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isActive
                                            ? const Color(0xFF1D1D1F)
                                            : Colors.transparent,
                                        width: isActive ? 2 : 0,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Image.network(
                                          widget.imageUrls[i],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.imageUrls.length, (i) {
                            final active = i == _index;
                            return Container(
                              width: active ? 20 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Primary info block
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Replace brand pill with highlights (fallback to brand if none)
                  if (_hasHighlights)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: (widget.highlights ?? const [])
                          .take(3)
                          .map(
                            (h) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE5E5EA),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                h,
                                style: const TextStyle(
                                  color: Color(0xFF1D1D1F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.brand,
                        style: const TextStyle(
                          color: Color(0xFF1D1D1F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF6E6E73),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Price (with currency if provided)
                  Text(
                    "${(widget.currency != null && widget.currency!.isNotEmpty) ? '${widget.currency} ' : ''}${widget.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                    style: const TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.mrp != null && (widget.mrp ?? 0) > widget.price)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "MRP ${(widget.currency != null && widget.currency!.isNotEmpty) ? '${widget.currency} ' : ''}${widget.mrp!.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Color(0xFF6E6E73),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Rating
                  if (widget.rating > 0) ...[
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < widget.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFF1D1D1F),
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          "${widget.rating} (${widget.reviewCount} reviews)",
                          style: const TextStyle(
                            color: Color(0xFF6E6E73),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  // Quick highlight chips (monochrome) - show here only if not already shown above
                  if (!_hasHighlights &&
                      (widget.highlights ?? const []).isNotEmpty)
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.highlights!.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE5E5EA),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              widget.highlights![i],
                              style: const TextStyle(
                                color: Color(0xFF6E6E73),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_hasHighlights &&
                      (widget.highlights ?? const []).isNotEmpty)
                    const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1D1D1F),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF6E6E73),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Product Details'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Inline tab content (single scroll for whole page)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  if (_tabController.index == 0) {
                    return _buildProductDetailsTab();
                  } else {
                    return _buildReviewsTab();
                  }
                },
              ),
            ),
            const SizedBox(height: 100), // Extra space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Price section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          color: Color(0xFF6E6E73),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(widget.currency != null && widget.currency!.isNotEmpty) ? '${widget.currency} ' : ''}${(_quantity > 0 ? widget.price * _quantity : widget.price).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                        style: const TextStyle(
                          color: Color(0xFF1D1D1F),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // QuantityCartButton with full cart functionality
                if (widget.agentId != null &&
                    widget.agentName != null &&
                    widget.productId != null)
                  Expanded(
                    flex: 2,
                    child: QuantityCartButton(
                      productId: widget.productId!,
                      productName: widget.productName,
                      agentId: widget.agentId!,
                      agentName: widget.agentName!,
                      price: widget.price,
                      imageUrl: widget.imageUrls.isNotEmpty
                          ? widget.imageUrls.first
                          : null,
                      description: widget.description,
                      onSuccess: () {
                        setState(() {
                          _quantity = 1;
                        });
                      },
                    ),
                  )
                else
                  // Fallback to basic button if agent info is missing
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _quantity = 1;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product added to cart (demo mode)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D1D1F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6E6E73),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1D1D1F),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick meta
        if (widget.sku != null || widget.stockQuantity != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E5EA)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.sku != null) _buildDetailRow('SKU', widget.sku!),
                // availability hidden per request
                if (widget.stockQuantity != null) ...[
                  const SizedBox(height: 4),
                  _buildDetailRow('Stock', widget.stockQuantity.toString()),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Attributes/specs
        if ((widget.attributes ?? const {}).isNotEmpty ||
            widget.material != null ||
            widget.dimensions != null) ...[
          const Text(
            'Specifications',
            style: TextStyle(
              color: Color(0xFF1D1D1F),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if ((widget.attributes ?? const {}).isNotEmpty) ...[
            ...widget.attributes!.entries
                .where((e) => (e.value).toString().trim().isNotEmpty)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildDetailRow(e.key, e.value),
                  ),
                ),
          ],
          if (widget.material != null) ...[
            _buildDetailRow('Material', widget.material!),
            const SizedBox(height: 4),
          ],
          if (widget.dimensions != null) ...[
            _buildDetailRow('Dimensions', widget.dimensions!),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 8),
        ],
        // Classification
        if ((widget.categories ?? const []).isNotEmpty ||
            (widget.tags ?? const []).isNotEmpty) ...[
          if ((widget.categories ?? const []).isNotEmpty)
            _buildDetailRow('Categories', widget.categories!.join(', ')),
          if ((widget.tags ?? const []).isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildDetailRow('Tags', widget.tags!.join(', ')),
          ],
          const SizedBox(height: 16),
        ],
        // Description
        const Text(
          'Description',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: const TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.longDescription,
          style: const TextStyle(
            color: Color(0xFF6E6E73),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        // Concierge help section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/avtar_agent.png'),
            ),
            title: const Text(
              'Need Help?',
              style: TextStyle(
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text(
              'Contact our concierge for personalized assistance',
              style: TextStyle(
                color: Color(0xFF6E6E73),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF6E6E73)),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Write a review
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write a review',
                style: TextStyle(
                  color: Color(0xFF1D1D1F),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _userRating;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: const Color(0xFF1D1D1F),
                        size: 24,
                      ),
                      onPressed: () => setState(() => _userRating = i + 1),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1D1D1F)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D1D1F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final text = _reviewController.text.trim();
                    if (_userRating == 0 || text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please provide a rating and a review.',
                          ),
                        ),
                      );
                      return;
                    }
                    // TODO: integrate API call to submit review
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Thank you! Your review has been submitted.',
                        ),
                      ),
                    );
                    setState(() {
                      _userRating = 0;
                      _reviewController.clear();
                    });
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Overall rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Rating display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.rating.toString(),
                        style: const TextStyle(
                          color: Color(0xFF1D1D1F),
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < widget.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFF1D1D1F),
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.reviewCount} reviews',
                        style: const TextStyle(
                          color: Color(0xFF6E6E73),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Rating breakdown
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        final rating = 5 - index;
                        final percentage = rating == 5
                            ? 0.8
                            : rating == 4
                            ? 0.15
                            : rating == 3
                            ? 0.05
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                '$rating',
                                style: const TextStyle(
                                  color: Color(0xFF6E6E73),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.star,
                                color: Color(0xFF1D1D1F),
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E5EA),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: percentage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1D1D1F),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Individual reviews
        const Text(
          'Customer Reviews',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Sample reviews
        ...List.generate(3, (index) {
          final reviews = [
            {
              'name': 'Sarah M.',
              'rating': 5,
              'date': '2 days ago',
              'comment':
                  'Absolutely stunning quality! The craftsmanship is exceptional and the attention to detail is remarkable. Highly recommend!',
            },
            {
              'name': 'Michael R.',
              'rating': 4,
              'date': '1 week ago',
              'comment':
                  'Great product overall. The quality is good and it arrived on time. Would definitely purchase again.',
            },
            {
              'name': 'Emma L.',
              'rating': 5,
              'date': '2 weeks ago',
              'comment':
                  'Exceeded my expectations! The product is even better than described. Fast shipping and excellent customer service.',
            },
          ];
          final review = reviews[index];
          final name = review['name'] as String;
          final rating = review['rating'] as int;
          final date = review['date'] as String;
          final comment = review['comment'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE5E5EA),
                      child: Text(
                        name.substring(0, 1),
                        style: const TextStyle(
                          color: Color(0xFF1D1D1F),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Color(0xFF1D1D1F),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              ...List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: const Color(0xFF1D1D1F),
                                  size: 14,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                date,
                                style: const TextStyle(
                                  color: Color(0xFF6E6E73),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  comment,
                  style: const TextStyle(
                    color: Color(0xFF1D1D1F),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
