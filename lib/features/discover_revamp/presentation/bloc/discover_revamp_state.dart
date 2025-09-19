part of 'discover_revamp_bloc.dart';

class DiscoverRevampState extends Equatable {
  final bool isLoading;
  final List<DiscoverRevampItem> items;
  final String? errorMessage;

  const DiscoverRevampState({
    required this.isLoading,
    required this.items,
    required this.errorMessage,
  });

  const DiscoverRevampState.initial()
    : isLoading = false,
      items = const [],
      errorMessage = null;

  DiscoverRevampState copyWith({
    bool? isLoading,
    List<DiscoverRevampItem>? items,
    String? errorMessage,
  }) {
    return DiscoverRevampState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}
