part of 'relay_bloc.dart';

abstract class RelayEvent extends Equatable {
  const RelayEvent();

  @override
  List<Object?> get props => [];
}

/// Request to subscribe to relay connection state updates.
class RelaySubscriptionRequested extends RelayEvent {
  const RelaySubscriptionRequested();
}
