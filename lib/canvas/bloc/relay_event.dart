part of 'relay_bloc.dart';

abstract class RelayEvent extends Equatable {
  const RelayEvent();

  @override
  List<Object?> get props => [];
}

/// Request to subscribe to relay pool state updates.
class RelaySubscriptionRequested extends RelayEvent {
  const RelaySubscriptionRequested();
}

/// Request to add a new relay.
class RelayAddRequested extends RelayEvent {
  const RelayAddRequested(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}

/// Request to remove a relay.
class RelayRemoveRequested extends RelayEvent {
  const RelayRemoveRequested(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}
