import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';
import 'package:relay_settings_repository/relay_settings_repository.dart';

part 'relay_event.dart';
part 'relay_state.dart';

class RelayBloc extends Bloc<RelayEvent, RelayState> {
  RelayBloc({
    required PixelRepository pixelRepository,
    required RelaySettingsRepository relaySettingsRepository,
  }) : _pixelRepository = pixelRepository,
       _relaySettings = relaySettingsRepository,
       super(const RelayState()) {
    on<RelaySubscriptionRequested>(_onSubscriptionRequested);
    on<RelayAddRequested>(_onAddRequested);
    on<RelayRemoveRequested>(_onRemoveRequested);
  }

  final PixelRepository _pixelRepository;
  final RelaySettingsRepository _relaySettings;

  Future<void> _onSubscriptionRequested(
    RelaySubscriptionRequested event,
    Emitter<RelayState> emit,
  ) async {
    await emit.forEach<RelayPoolState>(
      _pixelRepository.poolState,
      onData: (poolState) => RelayState(
        connectedCount: poolState.connectedCount,
        totalCount: poolState.totalCount,
        relayStates: poolState.relayStates,
        overallState: poolState.overallState,
      ),
    );
  }

  Future<void> _onAddRequested(
    RelayAddRequested event,
    Emitter<RelayState> emit,
  ) async {
    final url = event.url.trim();

    // Validate URL
    if (!_isValidRelayUrl(url)) return;

    // Check if pool is initialized
    if (!_pixelRepository.pool.isInitialized) return;

    // Add to pool (connects automatically)
    await _pixelRepository.pool.addRelay(url);

    // Persist
    await _relaySettings.addRelay(url);
  }

  Future<void> _onRemoveRequested(
    RelayRemoveRequested event,
    Emitter<RelayState> emit,
  ) async {
    // Prevent removing last relay
    if (state.totalCount <= 1) return;

    // Check if pool is initialized
    if (!_pixelRepository.pool.isInitialized) return;

    // Remove from pool
    await _pixelRepository.pool.removeRelay(event.url);

    // Persist
    await _relaySettings.removeRelay(event.url);
  }

  bool _isValidRelayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'wss' || uri.scheme == 'ws';
    } on Object {
      return false;
    }
  }
}
