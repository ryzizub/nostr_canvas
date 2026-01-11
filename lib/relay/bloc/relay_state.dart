part of 'relay_bloc.dart';

class RelayState extends Equatable {
  const RelayState({
    this.connectionState = ConnectionState.disconnected,
  });

  final ConnectionState connectionState;

  @override
  List<Object?> get props => [connectionState];

  RelayState copyWith({
    ConnectionState? connectionState,
  }) {
    return RelayState(
      connectionState: connectionState ?? this.connectionState,
    );
  }
}
