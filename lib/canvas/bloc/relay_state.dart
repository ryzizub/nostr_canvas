part of 'relay_bloc.dart';

class RelayState extends Equatable {
  const RelayState({
    this.connectedCount = 0,
    this.totalCount = 0,
    this.relayStates = const {},
    this.overallState = ConnectionState.disconnected,
  });

  /// Number of connected relays.
  final int connectedCount;

  /// Total number of relays in the pool.
  final int totalCount;

  /// Per-relay connection states.
  final Map<String, ConnectionState> relayStates;

  /// Overall state (connected if any relay is connected).
  final ConnectionState overallState;

  /// Helper for display: "X/Y" format.
  String get statusText => '$connectedCount/$totalCount';

  @override
  List<Object?> get props => [
    connectedCount,
    totalCount,
    relayStates,
    overallState,
  ];

  RelayState copyWith({
    int? connectedCount,
    int? totalCount,
    Map<String, ConnectionState>? relayStates,
    ConnectionState? overallState,
  }) {
    return RelayState(
      connectedCount: connectedCount ?? this.connectedCount,
      totalCount: totalCount ?? this.totalCount,
      relayStates: relayStates ?? this.relayStates,
      overallState: overallState ?? this.overallState,
    );
  }
}
