// Base bloc for shared bloc patterns
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Base event
abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object?> get props => [];
}

// Base state
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

// Base bloc
abstract class BaseBloc<Event extends BaseEvent, State extends BaseState>
    extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  // Common error handling
  void handleError(dynamic error, Emitter<State> emit) {
    // Override in subclasses for specific error handling
    emit(ErrorState(error.toString()) as State);
  }
}

// Common states
class InitialState extends BaseState {}

class LoadingState extends BaseState {}

class ErrorState extends BaseState {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
