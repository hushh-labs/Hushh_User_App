import '../../domain/entities/agent_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../services/discover_business_service.dart';

class GetAgentsWithCategories {
  final DiscoverBusinessService _businessService;

  GetAgentsWithCategories(this._businessService);

  Future<List<AgentWithCategories>> execute() async {
    return await _businessService.getAgentsWithCategories();
  }
}

class AgentWithCategories {
  final AgentEntity agent;
  final List<CategoryEntity> categories;

  const AgentWithCategories({required this.agent, required this.categories});

  String get servicesText {
    if (categories.isEmpty) return 'Concierge';
    return categories.map((c) => c.name).join(', ');
  }
}
