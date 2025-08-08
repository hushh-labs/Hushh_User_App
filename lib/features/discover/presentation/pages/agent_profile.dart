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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agent Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Agent Header Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar with proper image handling
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA342FF), Color(0xFFE54D60)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(52),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        agent['avatar'] != null && agent['avatar']!.isNotEmpty
                        ? NetworkImage(agent['avatar']!)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: agent['avatar'] == null || agent['avatar']!.isEmpty
                        ? Text(
                            _getInitials(agent['name'] ?? 'A'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Agent Name
                Text(
                  agent['name'] ?? 'Agent Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Company
                Text(
                  agent['company'] ?? 'Company',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                // Categories
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoadingCategories)
                  _buildCategoriesShimmer()
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.isNotEmpty
                        ? categories
                              .map(
                                (category) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    category['name'] ?? 'Unknown Category',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList()
                        : [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'No categories available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                  ),
              ],
            ),
          ),
          // Tab Bar
          AgentProfileTabBar(
            tabController: _tabController,
            onTap: (index) {
              _tabController.animateTo(index);
            },
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildLookbooksTab(), _buildProductsTab(products)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookbooksTab() {
    if (isLoadingLookbooks) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading lookbooks...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (lookbooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty-lookbook.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 16),
            const Text(
              'Lookbooks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No lookbooks available yet',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LookBooksListView(
        lookbooks: lookbooks,
        products: products,
        fromChat: false,
        sendLookBook: false,
      ),
    );
  }

  Widget _buildProductsTab(List<dynamic> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              // Product Image with proper handling
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    product['imageUrl'] != null &&
                        product['imageUrl']!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 40,
                            );
                          },
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.grey, size: 40),
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Product Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product['id'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: \$${(product['price'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat Icon
              IconButton(
                onPressed: _isLoading
                    ? null
                    : () => _handleProductChat(product),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFA342FF),
                          ),
                        ),
                      )
                    : const Icon(Icons.message, color: Color(0xFFA342FF)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesShimmer() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        3,
        (index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 80 + (index * 20.0), // Different widths for variety
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[400],
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
      final inquiryMessage =
          '''
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
