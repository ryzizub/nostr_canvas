import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_canvas/canvas/bloc/relay_bloc.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';
import 'package:relay_settings_repository/relay_settings_repository.dart';

class MockPixelRepository extends Mock implements PixelRepository {}

class MockRelaySettingsRepository extends Mock
    implements RelaySettingsRepository {}

class MockRelayPool extends Mock implements RelayPool {}

void main() {
  group('RelayBloc', () {
    late PixelRepository pixelRepository;
    late RelaySettingsRepository relaySettingsRepository;
    late RelayPool relayPool;

    setUp(() {
      pixelRepository = MockPixelRepository();
      relaySettingsRepository = MockRelaySettingsRepository();
      relayPool = MockRelayPool();
      when(() => pixelRepository.pool).thenReturn(relayPool);
    });

    test('initial state has disconnected overall state', () {
      when(() => pixelRepository.poolState).thenAnswer(
        (_) => const Stream<RelayPoolState>.empty(),
      );
      expect(
        RelayBloc(
          pixelRepository: pixelRepository,
          relaySettingsRepository: relaySettingsRepository,
        ).state,
        equals(const RelayState()),
      );
      expect(
        RelayBloc(
          pixelRepository: pixelRepository,
          relaySettingsRepository: relaySettingsRepository,
        ).state.overallState,
        equals(ConnectionState.disconnected),
      );
    });

    group('RelaySubscriptionRequested', () {
      blocTest<RelayBloc, RelayState>(
        'emits connected state when stream emits connected pool state',
        setUp: () {
          when(() => pixelRepository.poolState).thenAnswer(
            (_) => Stream.value(
              const RelayPoolState(
                connectedCount: 1,
                totalCount: 1,
                relayStates: {'wss://relay.example.com': ConnectionState.connected},
                overallState: ConnectionState.connected,
              ),
            ),
          );
        },
        build: () => RelayBloc(
          pixelRepository: pixelRepository,
          relaySettingsRepository: relaySettingsRepository,
        ),
        act: (bloc) => bloc.add(const RelaySubscriptionRequested()),
        expect: () => [
          const RelayState(
            connectedCount: 1,
            totalCount: 1,
            relayStates: {'wss://relay.example.com': ConnectionState.connected},
            overallState: ConnectionState.connected,
          ),
        ],
      );

      blocTest<RelayBloc, RelayState>(
        'emits connecting then connected states',
        setUp: () {
          when(() => pixelRepository.poolState).thenAnswer(
            (_) => Stream.fromIterable([
              const RelayPoolState(
                connectedCount: 0,
                totalCount: 1,
                relayStates: {'wss://relay.example.com': ConnectionState.connecting},
                overallState: ConnectionState.connecting,
              ),
              const RelayPoolState(
                connectedCount: 1,
                totalCount: 1,
                relayStates: {'wss://relay.example.com': ConnectionState.connected},
                overallState: ConnectionState.connected,
              ),
            ]),
          );
        },
        build: () => RelayBloc(
          pixelRepository: pixelRepository,
          relaySettingsRepository: relaySettingsRepository,
        ),
        act: (bloc) => bloc.add(const RelaySubscriptionRequested()),
        expect: () => [
          const RelayState(
            totalCount: 1,
            relayStates: {'wss://relay.example.com': ConnectionState.connecting},
            overallState: ConnectionState.connecting,
          ),
          const RelayState(
            connectedCount: 1,
            totalCount: 1,
            relayStates: {'wss://relay.example.com': ConnectionState.connected},
            overallState: ConnectionState.connected,
          ),
        ],
      );

      blocTest<RelayBloc, RelayState>(
        'emits error state when all relays have errors',
        setUp: () {
          when(() => pixelRepository.poolState).thenAnswer(
            (_) => Stream.value(
              const RelayPoolState(
                connectedCount: 0,
                totalCount: 1,
                relayStates: {'wss://relay.example.com': ConnectionState.error},
                overallState: ConnectionState.error,
              ),
            ),
          );
        },
        build: () => RelayBloc(
          pixelRepository: pixelRepository,
          relaySettingsRepository: relaySettingsRepository,
        ),
        act: (bloc) => bloc.add(const RelaySubscriptionRequested()),
        expect: () => [
          const RelayState(
            totalCount: 1,
            relayStates: {'wss://relay.example.com': ConnectionState.error},
            overallState: ConnectionState.error,
          ),
        ],
      );
    });
  });
}
