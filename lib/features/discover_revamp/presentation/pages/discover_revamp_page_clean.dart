import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/discover_revamp_bloc.dart';
import '../widgets/discover_header.dart';
import '../widgets/discover_item_card.dart';
import '../widgets/section_heading.dart';
import '../widgets/top_categories_row.dart';
import '../widgets/brands_marquee.dart';
import '../widgets/service_banner_carousel.dart';
import '../widgets/concierge_agent_card.dart' hide ConciergeAgentData;
import '../services/discover_presentation_service.dart'
    show
        DisplayAgentData,
        DiscoverPresentationService,
        DiscoverPresentationException;
import '../widgets/concierge_agent_card.dart' show ConciergeAgentData;
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/route_paths.dart';
import 'agent_profile_revamp_page.dart';
import 'partner_agents_page.dart';

class DiscoverRevampPageClean extends StatefulWidget {
  const DiscoverRevampPageClean({super.key});

  @override
  State<DiscoverRevampPageClean> createState() =>
      _DiscoverRevampPageCleanState();
}

class _DiscoverRevampPageCleanState extends State<DiscoverRevampPageClean> {
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DiscoverPresentationService _presentationService =
      DiscoverPresentationService();

  List<ConciergeAgentData> _agents = [];
  Map<String, String> _agentIdMap = {}; // Maps agent name to agentId
  bool _loadingAgents = true;
  String? _errorMessage;

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

  Future<void> _loadAgents() async {
    if (!mounted) return;

    setState(() {
      _loadingAgents = true;
      _errorMessage = null;
    });

    try {
      final displayAgents = await _presentationService.getDisplayAgents();
      if (mounted) {
        // Convert DisplayAgentData to ConciergeAgentData and store agentId mapping
        final convertedAgents = <ConciergeAgentData>[];
        final agentIdMap = <String, String>{};

        for (final displayAgent in displayAgents) {
          final conciergeAgent = ConciergeAgentData(
            name: displayAgent.name,
            location: displayAgent.location,
            services: displayAgent.services,
            rating: displayAgent.rating,
            imageUrl: displayAgent.imageUrl,
            brand: displayAgent.brand,
            industry: displayAgent.industry,
            isFavorite: displayAgent.isFavorite,
          );
          convertedAgents.add(conciergeAgent);
          agentIdMap[displayAgent.name] = displayAgent.agentId;
        }

        setState(() {
          _agents = convertedAgents;
          _agentIdMap = agentIdMap;
          _loadingAgents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loadingAgents = false;
        });
      }
    }
  }

  void _handleAgentTap(ConciergeAgentData agent) {
    final agentId =
        _agentIdMap[agent.name] ??
        agent.name.toLowerCase().replaceAll(' ', '_');
    context.pushNamed(
      RouteNames.agentProfileRevamp,
      extra: AgentProfileRevampArgs(agentId: agentId, agentName: agent.name),
    );
  }

  void _handleSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      context.pushNamed(
        'searchResults',
        extra: SearchResultPageArgs(query: query.trim(), filters: []),
      );
    }
  }

  void _navigateToPartnerAgents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PartnerAgentsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: BlocBuilder<DiscoverRevampBloc, DiscoverRevampState>(
        builder: (context, state) {
          return _buildContent(state);
        },
      ),
    );
  }

  Widget _buildContent(DiscoverRevampState state) {
    final headerWidgets = <Widget>[
      const SizedBox(height: 8),
      DiscoverHeader(
        primaryPurple: primaryPurple,
        primaryPink: primaryPink,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        onFilterTap: () {},
        onSearchSubmitted: _handleSearchSubmitted,
      ),
      const SizedBox(height: 16),
      const ServiceBannerCarousel(),
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
        onActionTap: _navigateToPartnerAgents,
      ),
      const BrandsMarquee(),
      SectionHeading(
        title: 'Partner Agents',
        actionText: 'View all',
        leadingIcon: Icons.person_outline,
        onActionTap: _navigateToPartnerAgents,
      ),
      const SizedBox(height: 12),
      _buildAgentsSection(),
      const SizedBox(height: 16),
    ];

    if (state.isLoading) {
      return _buildListView(headerWidgets, isLoading: true);
    }

    if (state.errorMessage != null) {
      return _buildListView(headerWidgets, errorMessage: state.errorMessage);
    }

    if (state.items.isEmpty) {
      return _buildListView(headerWidgets);
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
  }

  Widget _buildListView(
    List<Widget> headerWidgets, {
    bool isLoading = false,
    String? errorMessage,
  }) {
    return ListView(
      children: [
        ...headerWidgets,
        if (isLoading) ...[
          const SizedBox(height: 80),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 80),
        ],
        if (errorMessage != null) ...[
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(child: Text(errorMessage)),
          ),
        ],
        if (!isLoading && errorMessage == null) ...[
          const SizedBox(height: 120),
          const SizedBox(height: 120),
        ],
      ],
    );
  }

  Widget _buildAgentsSection() {
    if (_loadingAgents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load agents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadAgents, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_agents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No agents available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ConciergeAgentsGrid(
      onAgentTap: _handleAgentTap,
      agents: _agents,
      onFavoriteTap: (agent) {
        // Handle favorite tap
      },
    );
  }
}

// Helper class for search results arguments
class SearchResultPageArgs {
  final String query;
  final List<String> filters;

  const SearchResultPageArgs({required this.query, required this.filters});
}
