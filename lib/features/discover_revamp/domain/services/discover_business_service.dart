import '../entities/agent_entity.dart';
import '../entities/category_entity.dart';
import '../usecases/get_agents_with_categories.dart';
import '../../data/services/agent_data_service.dart';
import '../../data/services/category_data_service.dart';

class DiscoverBusinessService {
  final AgentDataService _agentDataService;
  final CategoryDataService _categoryDataService;

  DiscoverBusinessService({
    required AgentDataService agentDataService,
    required CategoryDataService categoryDataService,
  }) : _agentDataService = agentDataService,
       _categoryDataService = categoryDataService;

  Future<List<AgentWithCategories>> getAgentsWithCategories() async {
    try {
      // Get all active agents
      final agents = await _agentDataService.getActiveAgents();

      // Get categories for all agents in a single batch call
      final allCategoryIds = <String>{};
      for (final agent in agents) {
        allCategoryIds.addAll(agent.categories);
      }

      final categoriesMap = <String, CategoryEntity>{};
      if (allCategoryIds.isNotEmpty) {
        final categories = await _categoryDataService.getCategoriesByIds(
          allCategoryIds.toList(),
        );
        for (final category in categories) {
          categoriesMap[category.id] = category;
        }
      }

      // Combine agents with their categories
      final result = <AgentWithCategories>[];
      for (final agent in agents) {
        final agentCategories = <CategoryEntity>[];
        for (final categoryId in agent.categories) {
          final category = categoriesMap[categoryId];
          if (category != null) {
            agentCategories.add(category);
          }
        }

        result.add(
          AgentWithCategories(agent: agent, categories: agentCategories),
        );
      }

      return result;
    } catch (e) {
      throw Exception('Failed to load agents with categories: $e');
    }
  }

  Future<AgentEntity?> getAgentById(String agentId) async {
    return await _agentDataService.getAgentById(agentId);
  }

  Future<List<CategoryEntity>> getCategoriesForAgent(AgentEntity agent) async {
    if (agent.categories.isEmpty) return [];
    return await _categoryDataService.getCategoriesByIds(agent.categories);
  }
}
