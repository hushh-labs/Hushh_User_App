import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../widgets/agent_profile_tabbar.dart';
import '../widgets/lookbooks_list_view.dart';
import '../../data/models/lookbook_model.dart';
import '../../data/models/agent_product_model.dart';
import '../../data/datasources/firebase_discover_datasource.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart' as chat;
import '../../../chat/presentation/pages/regular_chat_page.dart';
import '../../../chat/domain/entities/chat_entity.dart';
import '../bloc/cart_bloc.dart';
import 'product_details_page.dart';

class AgentProfile extends StatefulWidget {
  final Map<String, dynamic> agent;

  const AgentProfile({super.key, required this.agent});

  @override
  State<AgentProfile> createState() => _AgentProfileState();
}

class _AgentProfileState extends State<AgentProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;
  bool _isLoading = false;

  // Lookbooks and products state
  List<LookbookModel> lookbooks = [];
  List<AgentProductModel> products = [];
  bool isLoadingLookbooks = true;
  bool isLoadingProducts = true;
  final FirebaseDiscoverDataSource _dataSource =
      FirebaseDiscoverDataSourceImpl();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadLookbooksAndProducts();
  }

  void _openProductDetails(Map<String, dynamic> product) {
    final agentId = widget.agent['agentId'] ?? widget.agent['id'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          product: product,
          agentId: agentId?.toString() ?? '',
          agentName: widget.agent['name'] ?? 'Agent',
        ),
      ),
    );
  }

  void _handleAddToCart(Map<String, dynamic> product) {
    try {
      final agentId =
          (widget.agent['agentId'] ?? widget.agent['id'])?.toString() ?? '';
      final agentName = widget.agent['name']?.toString() ?? 'Agent';
      final model = AgentProductModel(
        id: product['id']?.toString() ?? '',
        productName: product['name']?.toString() ?? '',
        productPrice: (product['price'] as num?)?.toDouble() ?? 0.0,
        productImage: product['imageUrl']?.toString(),
        stockQuantity: (product['stock'] as num?)?.toInt() ?? 0,
        productDescription: product['productDescription']?.toString(),
        createdAt: DateTime.now(),
      );
      context.read<CartBloc>().add(
            AddToCartEvent(
                product: model, agentId: agentId, agentName: agentName),
          );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to cart')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart unavailable'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
    try {
      final agentId = widget.agent['agentId'] ?? widget.agent['id'];
      if (agentId != null) {
        // Load lookbooks and products in parallel
        await Future.wait([_loadLookbooks(agentId), _loadProducts(agentId)]);
      }
    } catch (e) {
      debugPrint('Error loading lookbooks and products: $e');
    }
  }

  Future<void> _loadLookbooks(String agentId) async {
    try {
      final lookbooksData = await _dataSource.getAgentLookbooks(agentId);
      setState(() {
        lookbooks = lookbooksData;
        isLoadingLookbooks = false;
      });
    } catch (e) {
      debugPrint('Error loading lookbooks: $e');
      setState(() {
        isLoadingLookbooks = false;
      });
    }
  }

  Future<void> _loadProducts(String agentId) async {
    try {
      final productsData = await _dataSource.getAgentProducts(agentId);
      setState(() {
        products = productsData;
        isLoadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        isLoadingProducts = false;
      });
    }
  }

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
    final products = agent['products'] as List<dynamic>;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
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
          // Agent Header Section
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
                  // LinkedIn-like header: photo left, identity right
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
                              color: const Color(0xFFA342FF).withOpacity(0.25),
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
                              (agent['location'] ?? 'Location not available')
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
                  // Description/About section just below header
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
                        (agent['description'] ?? agent['bio'] ?? agent['about'])
                            .toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          height: 1.35,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Services section (categories)
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
                              colors: [Color(0xFFF8F9FF), Color(0xFFF0F2FF)],
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
          // Tab Bar
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
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [_buildProductsTab(products), _buildLookbooksTab()],
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LookBooksListView(
        lookbooks: lookbooks,
        products: products,
        fromChat: false,
        sendLookBook: false,
      ),
    );
  }

  Widget _buildProductsTab(List<dynamic> products) {
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
              onTap: () => _openProductDetails(product),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Enhanced Product Image with price tag overlay
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
                          child: product['imageUrl'] != null &&
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
                              borderRadius: BorderRadius.circular(12),
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
                    // Enhanced Product Details
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product['productDescription'] ??
                                  'No description available',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Spacer(),
                              // Actions aligned to the end
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _handleProductChat(product),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF111111),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.message_outlined,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Chat',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _handleAddToCart(product),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF111111),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_shopping_cart_outlined,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Add to Cart',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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

      // Create chat ID by combining user IDs
      final participantIds = [currentUser.uid, agentId]..sort();
      final chatId = participantIds.join('_');

      // Create chat bloc and handle chat creation/opening
      final chatBloc = chat.ChatBloc();

      // Open or create chat
      chatBloc.add(chat.OpenChatEvent(chatId));

      // Send automatic product inquiry message immediately
      _sendProductInquiryMessage(chatBloc, chatId, product);

      // Navigate to chat page
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

      // Create inquiry message
      final inquiryMessage = '''
Hi! I'm interested in learning more about your $productName.

Product Details:
• Name: $productName
• SKU: $productSku
• Price: \$$productPrice

Could you please provide more information about this product?''';

      // Add a small delay to ensure chat is initialized
      await Future.delayed(const Duration(milliseconds: 1000));

      // Send the text message using the passed chat bloc
      chatBloc.add(
        chat.SendMessageEvent(
          chatId: chatId,
          message: inquiryMessage,
          isBot: false,
        ),
      );

      // If there's a product image, send it as an image message
      if (productImage != null && productImage.isNotEmpty) {
        // Add a small delay to ensure the first message is sent
        await Future.delayed(const Duration(milliseconds: 500));

        // Send as image message with proper type and mediaUrl
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

// Custom SliverAppBar delegate for the tab bar
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
