import '../../domain/entities/agent_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_agents_with_categories.dart';
import '../../domain/services/discover_business_service.dart';
import '../../data/services/agent_data_service.dart';
import '../../data/services/category_data_service.dart';

/// Presentation layer service that coordinates between UI and business logic
/// This service follows clean architecture by not having direct data dependencies
class DiscoverPresentationService {
  final GetAgentsWithCategories _getAgentsWithCategories;
  final DiscoverBusinessService _businessService;

  DiscoverPresentationService._({
    required GetAgentsWithCategories getAgentsWithCategories,
    required DiscoverBusinessService businessService,
  }) : _getAgentsWithCategories = getAgentsWithCategories,
       _businessService = businessService;

  factory DiscoverPresentationService() {
    final agentDataService = AgentDataService();
    final categoryDataService = CategoryDataService();
    final businessService = DiscoverBusinessService(
      agentDataService: agentDataService,
      categoryDataService: categoryDataService,
    );
    final getAgentsWithCategories = GetAgentsWithCategories(businessService);

    return DiscoverPresentationService._(
      getAgentsWithCategories: getAgentsWithCategories,
      businessService: businessService,
    );
  }

  Future<List<DisplayAgentData>> getDisplayAgents() async {
    try {
      final agentsWithCategories = await _getAgentsWithCategories.execute();

      return agentsWithCategories.map((awc) {
        final agent = awc.agent;
        return DisplayAgentData(
          name: agent.name,
          location: agent.location ?? '—',
          services: awc.servicesText,
          rating: 4.8, // Default rating, could be part of agent entity later
          imageUrl: agent.displayImageUrl,
          brand: agent.brandName,
          industry: agent.industry,
          agentId: agent.id,
        );
      }).toList();
    } catch (e) {
      throw DiscoverPresentationException('Failed to load agents: $e');
    }
  }

  Future<AgentEntity?> getAgentById(String agentId) async {
    try {
      return await _businessService.getAgentById(agentId);
    } catch (e) {
      throw DiscoverPresentationException('Failed to load agent: $e');
    }
  }

  Future<List<CategoryEntity>> getCategoriesForAgent(AgentEntity agent) async {
    try {
      return await _businessService.getCategoriesForAgent(agent);
    } catch (e) {
      throw DiscoverPresentationException('Failed to load categories: $e');
    }
  }
}

class DisplayAgentData {
  final String name;
  final String location;
  final String services;
  final double rating;
  final String imageUrl;
  final String? brand;
  final String? industry;
  final String agentId;
  final bool isFavorite;

  const DisplayAgentData({
    required this.name,
    required this.location,
    required this.services,
    required this.rating,
    required this.imageUrl,
    this.brand,
    this.industry,
    required this.agentId,
    this.isFavorite = false,
  });
}

class DiscoverPresentationException implements Exception {
  final String message;

  const DiscoverPresentationException(this.message);

  @override
  String toString() => 'DiscoverPresentationException: $message';
}
