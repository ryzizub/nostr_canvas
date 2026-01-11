import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

part 'relay_event.dart';
part 'relay_state.dart';

class RelayBloc extends Bloc<RelayEvent, RelayState> {
  RelayBloc({
    required PixelRepository pixelRepository,
  })  : _pixelRepository = pixelRepository,
        super(const RelayState()) {
    on<RelaySubscriptionRequested>(_onSubscriptionRequested);
  }

  final PixelRepository _pixelRepository;

  Future<void> _onSubscriptionRequested(
    RelaySubscriptionRequested event,
    Emitter<RelayState> emit,
  ) async {
    await emit.forEach<ConnectionState>(
      _pixelRepository.connectionState,
      onData: (connectionState) => state.copyWith(
        connectionState: connectionState,
      ),
    );
  }
}
