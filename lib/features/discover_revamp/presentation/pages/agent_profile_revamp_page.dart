import 'package:flutter/material.dart';
// bloc already imported above
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/widgets/agent_profile_tabbar.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/widgets/lookbooks_list_view.dart';
import 'package:hushh_user_app/features/discover_revamp/presentation/widgets/lookbooks_list_view.dart'
    show LookbookRevampModel, AgentProductRevampModel;
import 'package:hushh_user_app/features/chat/presentation/bloc/chat_bloc.dart'
    as chat;
import 'package:hushh_user_app/features/chat/presentation/pages/regular_chat_page.dart';
import 'package:hushh_user_app/features/chat/domain/entities/chat_entity.dart';
// Removed CartBloc dependency for revamp isolation
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/agent_profile_bloc.dart';
import 'product_revamp_page.dart';
import '../widgets/quantity_cart_button.dart';

class AgentProfileRevampArgs {
  final String agentId;
  final String agentName;

  const AgentProfileRevampArgs({
    required this.agentId,
    required this.agentName,
  });
}

class AgentProfileRevampPage extends StatefulWidget {
  final Map<String, dynamic> agent;

  const AgentProfileRevampPage({super.key, required this.agent});

  @override
  State<AgentProfileRevampPage> createState() => _AgentProfileRevampPageState();
}

class _AgentProfileRevampPageState extends State<AgentProfileRevampPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;
  // kept for parity with old UI; referenced in chat flow state
  bool _isLoading = false;

  // Lookbooks and products state (from Bloc)
  List<LookbookRevampModel> lookbooks = [];
  List<AgentProductRevampModel> products = [];
  bool isLoadingLookbooks = true;
  bool isLoadingProducts = true;
  // No external datasource in revamp; we mock data for now

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadLookbooksAndProducts();
  }

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductRevampPage(
          productName: product['name'] ?? 'Product',
          brand: widget.agent['company'] ?? 'Brand',
          description:
              product['shortDescription'] ??
              product['productDescription'] ??
              'No description',
          longDescription: product['longDescription'] ?? '',
          imageUrls:
              (product['imageUrls'] is List && product['imageUrls'].isNotEmpty)
              ? List<String>.from(product['imageUrls'].map((e) => e.toString()))
              : (product['imageUrl'] != null && product['imageUrl'].isNotEmpty)
              ? [product['imageUrl']]
              : <String>[],
          price: (product['price'] ?? 0.0).toDouble(),
          highlights: (product['highlights'] is List)
              ? List<String>.from(
                  product['highlights'].map((e) => e.toString()),
                )
              : null,
          rating: (product['rating'] as num?)?.toDouble() ?? 0,
          reviewCount: (product['reviewCount'] as num?)?.toInt() ?? 0,
          // Extended Firestore fields
          sku: product['sku']?.toString(),
          availability: product['availability']?.toString(),
          stockQuantity: (product['stockQuantity'] as num?)?.toInt(),
          currency: product['currency']?.toString(),
          mrp: (product['mrp'] as num?)?.toDouble(),
          discountPercent: (product['discountPercent'] as num?)?.toDouble(),
          categories: (product['categories'] is List)
              ? List<String>.from(
                  product['categories'].map((e) => e.toString()),
                )
              : null,
          tags: (product['tags'] is List)
              ? List<String>.from(product['tags'].map((e) => e.toString()))
              : null,
          attributes: (product['attributes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ),
          videoUrls: (product['videoUrls'] is List)
              ? List<String>.from(product['videoUrls'].map((e) => e.toString()))
              : null,
          relatedProductIds: (product['relatedProductIds'] is List)
              ? List<String>.from(
                  product['relatedProductIds'].map((e) => e.toString()),
                )
              : null,
          // Material/Dimensions kept for compatibility
          material:
              (product['attributes'] != null &&
                  (product['attributes'] as Map<String, dynamic>?)!.containsKey(
                    'Material',
                  ))
              ? (product['attributes'] as Map<String, dynamic>)['Material']
                    .toString()
              : null,
          dimensions:
              (product['attributes'] != null &&
                  (product['attributes'] as Map<String, dynamic>?)!.containsKey(
                    'Dimensions',
                  ))
              ? (product['attributes'] as Map<String, dynamic>)['Dimensions']
                    .toString()
              : null,
          // Cart functionality - pass agent and product info
          agentId:
              widget.agent['agentId']?.toString() ??
              widget.agent['id']?.toString() ??
              'unknown_agent',
          agentName: widget.agent['name'] ?? 'Agent',
          productId: product['id']?.toString(),
        ),
      ),
    );
  }

  void _handleAddToCart(Map<String, dynamic> product) {}

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final agent = widget.agent;
      final agentCategories = agent['categories'] as List<dynamic>?;

      if (agentCategories != null && agentCategories.isNotEmpty) {
        final categoriesData = <Map<String, dynamic>>[];

        for (final categoryId in agentCategories) {
          final categoryDoc = await FirebaseFirestore.instance
              .collection('agent_categories')
              .doc(categoryId.toString())
              .get();

          if (categoryDoc.exists) {
            final data = categoryDoc.data()!;
            categoriesData.add({
              'id': categoryId,
              'name': data['name'] ?? 'Unknown Category',
              'description': data['description'] ?? '',
            });
          }
        }

        setState(() {
          categories = categoriesData;
          isLoadingCategories = false;
        });
      } else {
        setState(() {
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadLookbooksAndProducts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      lookbooks = [
        LookbookRevampModel(
          lookbookName: 'Summer Picks',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          products: ['p1', 'p2', 'p3', 'p4', 'p5'],
        ),
      ];
      products = [
        AgentProductRevampModel(id: 'p1', productImage: null),
        AgentProductRevampModel(id: 'p2', productImage: null),
        AgentProductRevampModel(id: 'p3', productImage: null),
        AgentProductRevampModel(id: 'p4', productImage: null),
        AgentProductRevampModel(id: 'p5', productImage: null),
      ];
      isLoadingLookbooks = false;
      isLoadingProducts = false;
    });
  }

  // Reserved for future real data hookup (kept to mirror old structure)
  Future<void> _loadLookbooks(String agentId) async {}

  // Reserved for future real data hookup (kept to mirror old structure)
  Future<void> _loadProducts(String agentId) async {}

  String _getInitials(String name) {
    if (name.isEmpty) return 'A';

    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }
    return 'A';
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final products = agent['products'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black87,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: const Text(
                  'Agent Profile',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(56),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFA342FF,
                                  ).withOpacity(0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: const Color(0xFFF5F5F5),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(52),
                                child: Image.asset(
                                  'assets/avtar_agent.png',
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      _getInitials(agent['name'] ?? 'A'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF666666),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agent['name'] ?? 'Agent Name',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  agent['company'] ?? 'Company',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  (agent['location'] ??
                                          'Location not available')
                                      .toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A8A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if ((agent['description'] ??
                              agent['bio'] ??
                              agent['about']) !=
                          null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (agent['description'] ??
                                    agent['bio'] ??
                                    agent['about'])
                                .toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF555555),
                              height: 1.35,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (!isLoadingCategories && categories.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((category) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF8F9FF),
                                    Color(0xFFF0F2FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE8EAFF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                category['name'] ?? 'Unknown Category',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A4A4A),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (isLoadingCategories) ...[
                        const SizedBox(height: 12),
                        _buildCategoriesShimmer(),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 60,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AgentProfileTabBar(
                      tabController: _tabController,
                      onTap: (index) {
                        _tabController.animateTo(index);
                      },
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Products tab from Bloc
                    BlocBuilder<AgentProfileBloc, AgentProfileState>(
                      builder: (context, state) {
                        final mappedProducts = state.products
                            .map(
                              (p) => {
                                'id': p.id,
                                'name': p.name,
                                'price': p.price,
                                'imageUrl': p.imageUrls.isNotEmpty
                                    ? p.imageUrls.first
                                    : null,
                                'productDescription': p.shortDescription,
                              },
                            )
                            .toList();
                        return _buildProductsTab(
                          mappedProducts,
                          state.products,
                        );
                      },
                    ),
                    _buildLookbooksTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFA342FF),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLookbooksTab() {
    if (isLoadingLookbooks) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA342FF)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading lookbooks...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (lookbooks.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/empty-lookbook.json',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 20),
              const Text(
                'No Lookbooks Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This agent hasn\'t created any lookbooks yet',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 4),
      child: BlocBuilder<AgentProfileBloc, AgentProfileState>(
        builder: (context, state) {
          final lb = state.lookbooks
              .map(
                (e) => LookbookRevampModel(
                  lookbookName: e.name,
                  createdAt: e.createdAt,
                  products: e.productIds,
                ),
              )
              .toList();
          final pr = state.products
              .map(
                (e) => AgentProductRevampModel(
                  id: e.id,
                  productImage: e.imageUrls.isNotEmpty
                      ? e.imageUrls.first
                      : null,
                ),
              )
              .toList();
          return Align(
            alignment: Alignment.topLeft,
            child: LookBooksListView(
              lookbooks: lb,
              products: pr,
              fromChat: false,
              sendLookBook: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsTab(List<dynamic> products, List<dynamic> originals) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 70,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              const Text(
                'No Products Available',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This agent hasn\'t added any products yet',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final String pid = (product['id'] ?? '').toString();
                dynamic full;
                for (final p in originals) {
                  final String pidCandidate =
                      (p.id?.toString() ?? p.id.toString());
                  if (pidCandidate == pid) {
                    full = p;
                    break;
                  }
                }
                if (full != null) {
                  final enriched = {
                    'id': full.id,
                    'name': full.name,
                    'price': full.price,
                    'shortDescription': full.shortDescription,
                    'longDescription': full.longDescription,
                    'imageUrls': full.imageUrls,
                    'highlights': full.highlights,
                    'rating': full.rating,
                    'reviewCount': full.reviewCount,
                    'attributes': full.attributes,
                    'categories': full.categories,
                    'tags': full.tags,
                    'sku': full.sku,
                    'availability': full.availability,
                    'stockQuantity': full.stockQuantity,
                    'currency': full.currency,
                    'mrp': full.mrp,
                    'discountPercent': full.discountPercent,
                    'videoUrls': full.videoUrls,
                    'relatedProductIds': full.relatedProductIds,
                  };
                  _openProductDetails(enriched);
                } else {
                  _openProductDetails(product);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE8E8E8),
                              width: 1,
                            ),
                          ),
                          child:
                              product['imageUrl'] != null &&
                                  product['imageUrl']!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    product['imageUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFFCCCCCC),
                                        size: 40,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFFCCCCCC),
                                  size: 40,
                                ),
                        ),
                        Positioned(
                          top: -6,
                          left: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${((product['price'] ?? 0.0) as num).toStringAsFixed(2)}'
                                  .replaceFirst('\u0000', ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'Product Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product['productDescription'] ??
                                'No description available',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Spacer(),
                              Flexible(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    // Chat button temporarily hidden
                                    // InkWell(
                                    //   borderRadius: BorderRadius.circular(20),
                                    //   onTap: () => _handleProductChat(product),
                                    //   child: Container(
                                    //     padding: const EdgeInsets.symmetric(
                                    //       horizontal: 10,
                                    //       vertical: 6,
                                    //     ),
                                    //     decoration: BoxDecoration(
                                    //       color: const Color(0xFF111111),
                                    //       borderRadius: BorderRadius.circular(
                                    //         10,
                                    //       ),
                                    //     ),
                                    //     child: const Row(
                                    //       mainAxisSize: MainAxisSize.min,
                                    //       children: [
                                    //         Icon(
                                    //           Icons.message_outlined,
                                    //           color: Colors.white,
                                    //           size: 14,
                                    //         ),
                                    //         SizedBox(width: 3),
                                    //         Text(
                                    //           'Chat',
                                    //           style: TextStyle(
                                    //             color: Colors.white,
                                    //             fontSize: 11,
                                    //             fontWeight: FontWeight.w600,
                                    //           ),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //   ),
                                    // ),
                                    QuantityCartButton(
                                      productId: product['id']?.toString(),
                                      productName: product['name'] ?? 'Product',
                                      agentId:
                                          widget.agent['agentId']?.toString() ??
                                          widget.agent['id']?.toString() ??
                                          'unknown_agent',
                                      agentName:
                                          widget.agent['name'] ?? 'Agent',
                                      price: ((product['price'] ?? 0.0) as num)
                                          .toDouble(),
                                      imageUrl: product['imageUrl']?.toString(),
                                      description: product['productDescription']
                                          ?.toString(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesShimmer() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(
        4,
        (index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            width: 80 + (index * 15.0),
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleProductChat(Map<String, dynamic> product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to start a chat'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final agentId = widget.agent['agentId'] ?? widget.agent['id'];
      if (agentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final participantIds = [currentUser.uid, agentId]..sort();
      final chatId = participantIds.join('_');

      final chatBloc = chat.ChatBloc();
      chatBloc.add(chat.OpenChatEvent(chatId));

      _sendProductInquiryMessage(chatBloc, chatId, product);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: chatBloc,
            child: RegularChatPage(
              chatId: chatId,
              userName: widget.agent['name'] ?? 'Agent',
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendProductInquiryMessage(
    chat.ChatBloc chatBloc,
    String chatId,
    Map<String, dynamic> product,
  ) async {
    try {
      final productName = product['name'] ?? 'Product';
      final productPrice = (product['price'] ?? 0.0).toStringAsFixed(2);
      final productImage = product['imageUrl'];
      final productSku = product['id'] ?? 'N/A';

      final inquiryMessage =
          '''
Hi! I'm interested in learning more about your $productName.

Product Details:
• Name: $productName
• SKU: $productSku
• Price: \$$productPrice

Could you please provide more information about this product?''';

      await Future.delayed(const Duration(milliseconds: 1000));

      chatBloc.add(
        chat.SendMessageEvent(
          chatId: chatId,
          message: inquiryMessage,
          isBot: false,
        ),
      );

      if (productImage != null && productImage.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        chatBloc.add(
          chat.SendMessageEvent(
            chatId: chatId,
            message: 'Product Image',
            isBot: false,
            messageType: MessageType.image,
            imageUrl: productImage,
          ),
        );
      }
    } catch (e) {
      print('Error sending product inquiry message: $e');
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
