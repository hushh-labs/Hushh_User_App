import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/agent_product_revamp.dart';
import '../../domain/entities/lookbook_revamp.dart';
import '../../domain/usecases/get_agent_profile_content.dart';

sealed class AgentProfileEvent {}

class LoadAgentProfile extends AgentProfileEvent {
  final String agentId;
  LoadAgentProfile(this.agentId);
}

class AgentProfileState {
  final bool isLoading;
  final List<AgentProductRevamp> products;
  final List<LookbookRevamp> lookbooks;
  final String? error;

  const AgentProfileState({
    this.isLoading = false,
    this.products = const [],
    this.lookbooks = const [],
    this.error,
  });

  AgentProfileState copyWith({
    bool? isLoading,
    List<AgentProductRevamp>? products,
    List<LookbookRevamp>? lookbooks,
    String? error,
  }) => AgentProfileState(
    isLoading: isLoading ?? this.isLoading,
    products: products ?? this.products,
    lookbooks: lookbooks ?? this.lookbooks,
    error: error,
  );
}

class AgentProfileBloc extends Bloc<AgentProfileEvent, AgentProfileState> {
  final GetAgentProfileContent getContent;

  AgentProfileBloc(this.getContent) : super(const AgentProfileState()) {
    on<LoadAgentProfile>((event, emit) async {
      emit(state.copyWith(isLoading: true, error: null));
      try {
        final (products, lookbooks) = await getContent(event.agentId);
        emit(
          state.copyWith(
            isLoading: false,
            products: products,
            lookbooks: lookbooks,
          ),
        );
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });
  }
}
