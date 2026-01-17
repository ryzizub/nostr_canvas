import 'package:equatable/equatable.dart';
import 'package:nostr_client/src/connection/connection_state.dart';

/// Aggregate state of the relay pool.
class RelayPoolState extends Equatable {
  /// Creates a relay pool state.
  const RelayPoolState({
    required this.connectedCount,
    required this.totalCount,
    required this.relayStates,
    required this.overallState,
  });

  /// Creates an empty/initial state.
  factory RelayPoolState.empty() => const RelayPoolState(
        connectedCount: 0,
        totalCount: 0,
        relayStates: {},
        overallState: ConnectionState.disconnected,
      );

  /// Number of connected relays.
  final int connectedCount;

  /// Total number of relays in the pool.
  final int totalCount;

  /// Per-relay connection states.
  final Map<String, ConnectionState> relayStates;

  /// Overall pool state.
  ///
  /// - [ConnectionState.connected] if any relay is connected
  /// - [ConnectionState.connecting] if any relay is connecting (none connected)
  /// - [ConnectionState.reconnecting] if any is reconnecting (none connected)
  /// - [ConnectionState.error] if all relays have errors
  /// - [ConnectionState.disconnected] otherwise
  final ConnectionState overallState;

  /// Helper for display: "X/Y" format.
  String get statusText => '$connectedCount/$totalCount';

  /// Creates a copy with updated fields.
  RelayPoolState copyWith({
    int? connectedCount,
    int? totalCount,
    Map<String, ConnectionState>? relayStates,
    ConnectionState? overallState,
  }) {
    return RelayPoolState(
      connectedCount: connectedCount ?? this.connectedCount,
      totalCount: totalCount ?? this.totalCount,
      relayStates: relayStates ?? this.relayStates,
      overallState: overallState ?? this.overallState,
    );
  }

  @override
  List<Object?> get props =>
      [connectedCount, totalCount, relayStates, overallState];
}
