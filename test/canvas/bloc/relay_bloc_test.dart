import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:nostr_place/canvas/bloc/relay_bloc.dart';
import 'package:pixel_repository/pixel_repository.dart';

class MockPixelRepository extends Mock implements PixelRepository {}

void main() {
  group('RelayBloc', () {
    late PixelRepository pixelRepository;

    setUp(() {
      pixelRepository = MockPixelRepository();
    });

    test('initial state has disconnected connection state', () {
      when(() => pixelRepository.connectionState).thenAnswer(
        (_) => const Stream.empty(),
      );
      expect(
        RelayBloc(pixelRepository: pixelRepository).state,
        equals(const RelayState()),
      );
      expect(
        RelayBloc(pixelRepository: pixelRepository).state.connectionState,
        equals(ConnectionState.disconnected),
      );
    });

    group('RelaySubscriptionRequested', () {
      blocTest<RelayBloc, RelayState>(
        'emits connected state when stream emits connected',
        setUp: () {
          when(() => pixelRepository.connectionState).thenAnswer(
            (_) => Stream.value(ConnectionState.connected),
          );
        },
        build: () => RelayBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const RelaySubscriptionRequested()),
        expect: () => [
          const RelayState(connectionState: ConnectionState.connected),
        ],
      );

      blocTest<RelayBloc, RelayState>(
        'emits connecting then connected states',
        setUp: () {
          when(() => pixelRepository.connectionState).thenAnswer(
            (_) => Stream.fromIterable([
              ConnectionState.connecting,
              ConnectionState.connected,
            ]),
          );
        },
        build: () => RelayBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const RelaySubscriptionRequested()),
        expect: () => [
          const RelayState(connectionState: ConnectionState.connecting),
          const RelayState(connectionState: ConnectionState.connected),
        ],
      );

      blocTest<RelayBloc, RelayState>(
        'emits reconnecting state when connection drops',
        setUp: () {
          when(() => pixelRepository.connectionState).thenAnswer(
            (_) => Stream.fromIterable([
              ConnectionState.connected,
              ConnectionState.reconnecting,
            ]),
          );
        },
        build: () => RelayBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const RelaySubscriptionRequested()),
        expect: () => [
          const RelayState(connectionState: ConnectionState.connected),
          const RelayState(connectionState: ConnectionState.reconnecting),
        ],
      );

      blocTest<RelayBloc, RelayState>(
        'emits error state when connection fails',
        setUp: () {
          when(() => pixelRepository.connectionState).thenAnswer(
            (_) => Stream.value(ConnectionState.error),
          );
        },
        build: () => RelayBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const RelaySubscriptionRequested()),
        expect: () => [
          const RelayState(connectionState: ConnectionState.error),
        ],
      );

      blocTest<RelayBloc, RelayState>(
        'emits disconnected state when explicitly disconnected',
        setUp: () {
          when(() => pixelRepository.connectionState).thenAnswer(
            (_) => Stream.value(ConnectionState.disconnected),
          );
        },
        build: () => RelayBloc(pixelRepository: pixelRepository),
        seed: () =>
            const RelayState(connectionState: ConnectionState.connected),
        act: (bloc) => bloc.add(const RelaySubscriptionRequested()),
        expect: () => [
          const RelayState(),
        ],
      );
    });
  });
}
