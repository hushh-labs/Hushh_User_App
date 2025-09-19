part of 'discover_revamp_bloc.dart';

abstract class DiscoverRevampEvent extends Equatable {
  const DiscoverRevampEvent();

  @override
  List<Object?> get props => [];
}

class DiscoverRevampLoadRequested extends DiscoverRevampEvent {
  const DiscoverRevampLoadRequested();
}
