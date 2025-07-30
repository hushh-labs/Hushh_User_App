import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/agent_model.dart';
import '../../data/models/agent_product_model.dart';
import '../../data/repositories/discover_repository_impl.dart';

// Events
abstract class AgentsProductsEvent extends Equatable {
  const AgentsProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAgentsAndProducts extends AgentsProductsEvent {
  const LoadAgentsAndProducts();
}

class LoadMoreAgents extends AgentsProductsEvent {
  const LoadMoreAgents();
}

class LoadAgentProducts extends AgentsProductsEvent {
  final String agentId;
  const LoadAgentProducts(this.agentId);

  @override
  List<Object?> get props => [agentId];
}

class LoadMoreAgentProducts extends AgentsProductsEvent {
  final String agentId;
  const LoadMoreAgentProducts(this.agentId);

  @override
  List<Object?> get props => [agentId];
}

// States
abstract class AgentsProductsState extends Equatable {
  const AgentsProductsState();

  @override
  List<Object?> get props => [];
}

class AgentsProductsInitial extends AgentsProductsState {}

class AgentsProductsLoading extends AgentsProductsState {}

class AgentsProductsLoaded extends AgentsProductsState {
  final List<AgentModel> agents;
  final Map<String, List<AgentProductModel>> agentProducts;
  final bool isLoadingMore;
  final bool hasMoreAgents;
  final Map<String, bool> hasMoreProducts;
  final Map<String, bool> isLoadingMoreProducts;

  const AgentsProductsLoaded({
    required this.agents,
    required this.agentProducts,
    this.isLoadingMore = false,
    this.hasMoreAgents = true,
    this.hasMoreProducts = const {},
    this.isLoadingMoreProducts = const {},
  });

  @override
  List<Object?> get props => [
    agents,
    agentProducts,
    isLoadingMore,
    hasMoreAgents,
    hasMoreProducts,
    isLoadingMoreProducts,
  ];

  AgentsProductsLoaded copyWith({
    List<AgentModel>? agents,
    Map<String, List<AgentProductModel>>? agentProducts,
    bool? isLoadingMore,
    bool? hasMoreAgents,
    Map<String, bool>? hasMoreProducts,
    Map<String, bool>? isLoadingMoreProducts,
  }) {
    return AgentsProductsLoaded(
      agents: agents ?? this.agents,
      agentProducts: agentProducts ?? this.agentProducts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreAgents: hasMoreAgents ?? this.hasMoreAgents,
      hasMoreProducts: hasMoreProducts ?? this.hasMoreProducts,
      isLoadingMoreProducts:
          isLoadingMoreProducts ?? this.isLoadingMoreProducts,
    );
  }
}

class AgentsProductsError extends AgentsProductsState {
  final String message;

  const AgentsProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AgentsProductsBloc
    extends Bloc<AgentsProductsEvent, AgentsProductsState> {
  final DiscoverRepositoryImpl _repository;
  static const int agentsPerPage = 15;
  static const int productsPerPage = 6;
  int _currentAgentPage = 0;
  final Map<String, int> _currentProductPages = {};

  AgentsProductsBloc(this._repository) : super(AgentsProductsInitial()) {
    on<LoadAgentsAndProducts>(_onLoadAgentsAndProducts);
    on<LoadMoreAgents>(_onLoadMoreAgents);
    on<LoadAgentProducts>(_onLoadAgentProducts);
    on<LoadMoreAgentProducts>(_onLoadMoreAgentProducts);
  }

  void _onLoadAgentsAndProducts(
    LoadAgentsAndProducts event,
    Emitter<AgentsProductsState> emit,
  ) async {
    emit(AgentsProductsLoading());

    try {
      // Load first batch of agents
      final agents = await _repository.getAgentsPaginated(0, agentsPerPage);

      // Load products for each agent
      final Map<String, List<AgentProductModel>> agentProducts = {};
      final Map<String, bool> hasMoreProducts = {};

      for (final agent in agents) {
        try {
          final products = await _repository.getAgentProductsPaginated(
            agent.agentId,
            0,
            productsPerPage,
          );
          agentProducts[agent.agentId] = products;
          hasMoreProducts[agent.agentId] = products.length == productsPerPage;
          _currentProductPages[agent.agentId] = 0;
        } catch (e) {
          agentProducts[agent.agentId] = [];
          hasMoreProducts[agent.agentId] = false;
        }
      }

      _currentAgentPage = 0;

      emit(
        AgentsProductsLoaded(
          agents: agents,
          agentProducts: agentProducts,
          hasMoreAgents: agents.length == agentsPerPage,
          hasMoreProducts: hasMoreProducts,
        ),
      );
    } catch (e) {
      emit(AgentsProductsError('Failed to load agents and products: $e'));
    }
  }

  void _onLoadMoreAgents(
    LoadMoreAgents event,
    Emitter<AgentsProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AgentsProductsLoaded && currentState.hasMoreAgents) {
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final nextPage = _currentAgentPage + 1;
        final newAgents = await _repository.getAgentsPaginated(
          nextPage * agentsPerPage,
          agentsPerPage,
        );

        if (newAgents.isNotEmpty) {
          final updatedAgents = [...currentState.agents, ...newAgents];
          final updatedHasMoreAgents = newAgents.length == agentsPerPage;

          // Load products for new agents
          final updatedAgentProducts =
              Map<String, List<AgentProductModel>>.from(
                currentState.agentProducts,
              );
          final updatedHasMoreProducts = Map<String, bool>.from(
            currentState.hasMoreProducts,
          );

          for (final agent in newAgents) {
            try {
              final products = await _repository.getAgentProductsPaginated(
                agent.agentId,
                0,
                productsPerPage,
              );
              updatedAgentProducts[agent.agentId] = products;
              updatedHasMoreProducts[agent.agentId] =
                  products.length == productsPerPage;
              _currentProductPages[agent.agentId] = 0;
            } catch (e) {
              updatedAgentProducts[agent.agentId] = [];
              updatedHasMoreProducts[agent.agentId] = false;
            }
          }

          _currentAgentPage = nextPage;

          emit(
            currentState.copyWith(
              agents: updatedAgents,
              agentProducts: updatedAgentProducts,
              isLoadingMore: false,
              hasMoreAgents: updatedHasMoreAgents,
              hasMoreProducts: updatedHasMoreProducts,
            ),
          );
        } else {
          emit(
            currentState.copyWith(isLoadingMore: false, hasMoreAgents: false),
          );
        }
      } catch (e) {
        emit(AgentsProductsError('Failed to load more agents: $e'));
      }
    }
  }

  void _onLoadAgentProducts(
    LoadAgentProducts event,
    Emitter<AgentsProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AgentsProductsLoaded) {
      try {
        final products = await _repository.getAgentProductsPaginated(
          event.agentId,
          0,
          productsPerPage,
        );

        final updatedAgentProducts = Map<String, List<AgentProductModel>>.from(
          currentState.agentProducts,
        );
        updatedAgentProducts[event.agentId] = products;

        final updatedHasMoreProducts = Map<String, bool>.from(
          currentState.hasMoreProducts,
        );
        updatedHasMoreProducts[event.agentId] =
            products.length == productsPerPage;

        _currentProductPages[event.agentId] = 0;

        emit(
          currentState.copyWith(
            agentProducts: updatedAgentProducts,
            hasMoreProducts: updatedHasMoreProducts,
          ),
        );
      } catch (e) {
        emit(AgentsProductsError('Failed to load agent products: $e'));
      }
    }
  }

  void _onLoadMoreAgentProducts(
    LoadMoreAgentProducts event,
    Emitter<AgentsProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AgentsProductsLoaded) {
      final hasMore = currentState.hasMoreProducts[event.agentId] ?? false;
      if (!hasMore) return;

      final updatedIsLoadingMoreProducts = Map<String, bool>.from(
        currentState.isLoadingMoreProducts,
      );
      updatedIsLoadingMoreProducts[event.agentId] = true;

      emit(
        currentState.copyWith(
          isLoadingMoreProducts: updatedIsLoadingMoreProducts,
        ),
      );

      try {
        final currentPage = _currentProductPages[event.agentId] ?? 0;
        final nextPage = currentPage + 1;
        final newProducts = await _repository.getAgentProductsPaginated(
          event.agentId,
          nextPage * productsPerPage,
          productsPerPage,
        );

        if (newProducts.isNotEmpty) {
          final currentProducts =
              currentState.agentProducts[event.agentId] ?? [];
          final updatedProducts = [...currentProducts, ...newProducts];

          final updatedAgentProducts =
              Map<String, List<AgentProductModel>>.from(
                currentState.agentProducts,
              );
          updatedAgentProducts[event.agentId] = updatedProducts;

          final updatedHasMoreProducts = Map<String, bool>.from(
            currentState.hasMoreProducts,
          );
          updatedHasMoreProducts[event.agentId] =
              newProducts.length == productsPerPage;

          final updatedIsLoadingMoreProducts = Map<String, bool>.from(
            currentState.isLoadingMoreProducts,
          );
          updatedIsLoadingMoreProducts[event.agentId] = false;

          _currentProductPages[event.agentId] = nextPage;

          emit(
            currentState.copyWith(
              agentProducts: updatedAgentProducts,
              hasMoreProducts: updatedHasMoreProducts,
              isLoadingMoreProducts: updatedIsLoadingMoreProducts,
            ),
          );
        } else {
          final updatedHasMoreProducts = Map<String, bool>.from(
            currentState.hasMoreProducts,
          );
          updatedHasMoreProducts[event.agentId] = false;

          final updatedIsLoadingMoreProducts = Map<String, bool>.from(
            currentState.isLoadingMoreProducts,
          );
          updatedIsLoadingMoreProducts[event.agentId] = false;

          emit(
            currentState.copyWith(
              hasMoreProducts: updatedHasMoreProducts,
              isLoadingMoreProducts: updatedIsLoadingMoreProducts,
            ),
          );
        }
      } catch (e) {
        final updatedIsLoadingMoreProducts = Map<String, bool>.from(
          currentState.isLoadingMoreProducts,
        );
        updatedIsLoadingMoreProducts[event.agentId] = false;

        emit(
          currentState.copyWith(
            isLoadingMoreProducts: updatedIsLoadingMoreProducts,
          ),
        );
        emit(AgentsProductsError('Failed to load more products: $e'));
      }
    }
  }
}
