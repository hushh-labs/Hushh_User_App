import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/discover_revamp_bloc.dart';
import '../widgets/discover_header.dart';
import '../widgets/discover_item_card.dart';
import '../widgets/section_heading.dart';
import '../widgets/top_categories_row.dart';
import '../widgets/brands_marquee.dart';
import '../widgets/service_banner_carousel.dart';
// import '../widgets/brands_marquee.dart';
// import '../widgets/luxury_categories_grid.dart';
import '../widgets/concierge_agent_card.dart';
import 'partner_agents_page.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/route_paths.dart';
import 'agent_profile_revamp_page.dart';

class DiscoverRevampPage extends StatefulWidget {
  const DiscoverRevampPage({super.key});

  @override
  State<DiscoverRevampPage> createState() => _DiscoverRevampPageState();
}

class _DiscoverRevampPageState extends State<DiscoverRevampPage> {
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ConciergeAgentData> _agents = [];
  List<Map<String, dynamic>> _agentDocs = [];
  bool _loadingAgents = true;
  final Map<String, String> _categoryNameCache = {};
  final bool _debugPrintUrls = true;

  String _firstNonEmptyString(List<dynamic> values) {
    for (final v in values) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // AppBar removed as requested. Header is rendered inside the body.

  Future<void> _loadAgents() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('Hushhagents')
          .get();
      final docs = qs.docs
          .map((d) => ({...d.data(), 'id': d.id}))
          .where(
            (a) => (a['isActive'] == true) && (a['isProfileComplete'] == true),
          )
          .toList();
      _agentDocs = docs;
      _agents = [];
      for (final a in docs) {
        final List<dynamic> rawCats = (a['categories'] is List)
            ? (a['categories'] as List)
            : const [];
        final resolved = await _resolveCategoryNames(rawCats);
        final servicesText = resolved.isNotEmpty
            ? resolved.join(', ')
            : 'Concierge';

        final imageUrl = _firstNonEmptyString([
          a['profilePicUrl'],
          a['ProfilePicUrl'],
          a['profilePicURL'],
          a['profileImageUrl'],
          a['profile_image_url'],
          a['photoUrl'],
          a['photoURL'],
          a['avatarUrl'],
        ]);
        if (_debugPrintUrls) {
          // Debug: inspect which URL is picked
          // ignore: avoid_print
          print('[DiscoverRevamp] agentId=${a['id']} name=${a['name']}');
          print('[DiscoverRevamp] picked imageUrl => ' + imageUrl);
          print(
            '[DiscoverRevamp] fields: profilePicUrl=${(a['profilePicUrl'] ?? '').toString()} | ProfilePicUrl=${(a['ProfilePicUrl'] ?? '').toString()} | profilePicURL=${(a['profilePicURL'] ?? '').toString()} | profileImageUrl=${(a['profileImageUrl'] ?? '').toString()} | profile_image_url=${(a['profile_image_url'] ?? '').toString()} | photoUrl=${(a['photoUrl'] ?? '').toString()} | photoURL=${(a['photoURL'] ?? '').toString()} | avatarUrl=${(a['avatarUrl'] ?? '').toString()}',
          );
          if (imageUrl.isEmpty) {
            // Log available keys to catch subtle typos in field names
            final keys = a.keys.join(', ');
            // ignore: avoid_print
            print('[DiscoverRevamp] available keys => [' + keys + ']');
          }
        }

        _agents.add(
          ConciergeAgentData(
            name: a['name']?.toString() ?? 'Agent',
            location: a['location']?.toString() ?? '—',
            services: servicesText,
            rating: 4.8,
            imageUrl: imageUrl.isNotEmpty
                ? imageUrl
                : 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=1080',
            brand: a['brandName']?.toString(),
            industry: a['industry']?.toString(),
          ),
        );
      }
    } catch (e) {
      // ignore and keep empty
    } finally {
      if (mounted) setState(() => _loadingAgents = false);
    }
  }

  Future<List<String>> _resolveCategoryNames(List<dynamic> categoryIds) async {
    if (categoryIds.isEmpty) return const [];
    final List<String> names = [];
    for (final dynamic raw in categoryIds) {
      final String id = raw.toString();
      if (_categoryNameCache.containsKey(id)) {
        names.add(_categoryNameCache[id]!);
        continue;
      }
      try {
        final doc = await FirebaseFirestore.instance
            .collection('agent_categories')
            .doc(id)
            .get();
        final name = (doc.data()?['name']?.toString() ?? id);
        _categoryNameCache[id] = name;
        names.add(name);
      } catch (_) {
        names.add(id);
      }
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: BlocBuilder<DiscoverRevampBloc, DiscoverRevampState>(
        builder: (context, state) {
          final headerWidgets = <Widget>[
            const SizedBox(height: 8),
            DiscoverHeader(
              primaryPurple: primaryPurple,
              primaryPink: primaryPink,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onFilterTap: () {},
              onSearchSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  context.pushNamed(
                    'searchResults',
                    extra: SearchResultPageArgs(
                      query: query.trim(),
                      filters: [],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            const ServiceBannerCarousel(),
            const SizedBox(height: 0),
            // New Luxury Categories Section (old hidden below)
            // const LuxuryCategoriesGrid(), // hidden per request

            // OLD CATEGORIES HIDDEN
            // const SectionHeading(
            //   title: 'Explore Top Categories',
            //   actionText: '',
            //   leadingIcon: Icons.auto_awesome,
            // ),
            // const SizedBox(height: 16),
            // ... old grid removed for brevity
            const SizedBox(height: 0),
            const SectionHeading(
              title: 'Explore Top Categories',
              actionText: '',
              leadingIcon: Icons.auto_awesome,
            ),
            const SizedBox(height: 6),
            const TopCategoriesRow(),
            SectionHeading(
              title: 'Partner Brands',
              actionText: 'View all',
              leadingIcon: Icons.auto_awesome,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PartnerAgentsPage(),
                  ),
                );
              },
            ),
            const BrandsMarquee(),

            // Concierge Agents Section
            SectionHeading(
              title: 'Partner Agents',
              actionText: 'View all',
              leadingIcon: Icons.person_outline,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PartnerAgentsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            if (_loadingAgents)
              const Center(child: CircularProgressIndicator())
            else
              ConciergeAgentsGrid(
                onAgentTap: (agent) {
                  final idx = _agents.indexWhere((a) => a.name == agent.name);
                  final doc = idx >= 0 ? _agentDocs[idx] : null;
                  final agentId =
                      (doc != null ? doc['agentId'] : null) ??
                      doc?['id'] ??
                      agent.name.toLowerCase().replaceAll(' ', '_');
                  context.pushNamed(
                    RouteNames.agentProfileRevamp,
                    extra: AgentProfileRevampArgs(
                      agentId: agentId,
                      agentName: agent.name,
                    ),
                  );
                },
                agents: _agents,
                onFavoriteTap: (agent) {
                  // Handle favorite tap
                },
              ),
            const SizedBox(height: 16),

            /* Popular places moved below top categories (temporarily hidden)
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Popular places',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'View all',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SegmentChips(),
            const SizedBox(height: 20),
            */
            // Sections removed: New Launches, Tech, Fashion
            // Section removed: More
          ];

          if (state.isLoading) {
            return ListView(
              children: [
                ...headerWidgets,
                const SizedBox(height: 80),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 80),
              ],
            );
          }
          if (state.errorMessage != null) {
            return ListView(
              children: [
                ...headerWidgets,
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(child: Text(state.errorMessage!)),
                ),
              ],
            );
          }

          if (state.items.isEmpty) {
            return ListView(
              children: [
                ...headerWidgets,
                const SizedBox(height: 120),
                const SizedBox(height: 120),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 0, bottom: 12),
            itemCount: headerWidgets.length + state.items.length,
            itemBuilder: (context, index) {
              if (index < headerWidgets.length) {
                return headerWidgets[index];
              }
              final item = state.items[index - headerWidgets.length];
              return DiscoverItemCard(
                title: item.title,
                subtitle: 'ID: ${item.id}',
                imageUrl: item.imageUrl,
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
