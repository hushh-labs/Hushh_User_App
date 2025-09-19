import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/discover_revamp_item.dart';
import '../../domain/usecases/get_discover_revamp_items.dart';

part 'discover_revamp_event.dart';
part 'discover_revamp_state.dart';

class DiscoverRevampBloc
    extends Bloc<DiscoverRevampEvent, DiscoverRevampState> {
  final GetDiscoverRevampItems getItems;

  DiscoverRevampBloc({required this.getItems})
    : super(const DiscoverRevampState.initial()) {
    on<DiscoverRevampLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    DiscoverRevampLoadRequested event,
    Emitter<DiscoverRevampState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await getItems();
    result.fold(
      (error) => emit(state.copyWith(isLoading: false, errorMessage: error)),
      (items) => emit(state.copyWith(isLoading: false, items: items)),
    );
  }
}
