import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_canvas/canvas/bloc/canvas_bloc.dart';
import 'package:pixel_repository/pixel_repository.dart';

class MockPixelRepository extends Mock implements PixelRepository {}

void main() {
  group('CanvasBloc', () {
    late PixelRepository pixelRepository;
    late StreamController<CanvasData> canvasUpdatesController;

    setUpAll(() {
      registerFallbackValue(const Position(0, 0));
      registerFallbackValue(Colors.black);
    });

    setUp(() {
      pixelRepository = MockPixelRepository();
      canvasUpdatesController = StreamController<CanvasData>.broadcast();
      when(
        () => pixelRepository.canvasUpdates,
      ).thenAnswer((_) => canvasUpdatesController.stream);
    });

    tearDown(() async {
      await canvasUpdatesController.close();
    });

    test('initial state has status initial', () {
      expect(
        CanvasBloc(pixelRepository: pixelRepository).state,
        equals(const CanvasState()),
      );
      expect(
        CanvasBloc(pixelRepository: pixelRepository).state.status,
        equals(CanvasStatus.initial),
      );
    });

    group('CanvasLoadRequested', () {
      const canvasData = CanvasData(width: 1000, height: 1000);

      blocTest<CanvasBloc, CanvasState>(
        'emits loading then ready status when load succeeds',
        setUp: () {
          when(() => pixelRepository.loadCanvas()).thenAnswer(
            (_) async => canvasData,
          );
        },
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const CanvasLoadRequested()),
        expect: () => [
          const CanvasState(status: CanvasStatus.loading),
          const CanvasState(status: CanvasStatus.ready, canvasData: canvasData),
        ],
      );

      blocTest<CanvasBloc, CanvasState>(
        'emits loading then error status when load fails',
        setUp: () {
          when(() => pixelRepository.loadCanvas()).thenThrow(
            Exception('Failed to load canvas'),
          );
        },
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const CanvasLoadRequested()),
        expect: () => [
          const CanvasState(status: CanvasStatus.loading),
          isA<CanvasState>()
              .having((s) => s.status, 'status', CanvasStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Failed to load canvas'),
              ),
        ],
      );
    });

    group('ZoomChanged', () {
      const canvasData = CanvasData(width: 1000, height: 1000);

      blocTest<CanvasBloc, CanvasState>(
        'does nothing when status is not ready',
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const ZoomChanged(2)),
        expect: () => <CanvasState>[],
      );

      blocTest<CanvasBloc, CanvasState>(
        'emits state with updated zoom level',
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        seed: () => const CanvasState(
          status: CanvasStatus.ready,
          canvasData: canvasData,
        ),
        act: (bloc) => bloc.add(const ZoomChanged(2.5)),
        expect: () => [
          isA<CanvasState>().having(
            (s) => s.zoomLevel,
            'zoom level',
            equals(2.5),
          ),
        ],
      );

      blocTest<CanvasBloc, CanvasState>(
        'preserves canvas data and camera offset',
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        seed: () => const CanvasState(
          status: CanvasStatus.ready,
          canvasData: canvasData,
          cameraPosition: Offset(50, 100),
        ),
        act: (bloc) => bloc.add(const ZoomChanged(3)),
        expect: () => [
          isA<CanvasState>()
              .having((s) => s.canvasData, 'canvas data', equals(canvasData))
              .having(
                (s) => s.cameraPosition,
                'camera offset',
                equals(const Offset(50, 100)),
              ),
        ],
      );
    });

    group('CameraPositionChanged', () {
      const canvasData = CanvasData(width: 1000, height: 1000);

      blocTest<CanvasBloc, CanvasState>(
        'does nothing when status is not ready',
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const CameraPositionChanged(Offset(10, 20))),
        expect: () => <CanvasState>[],
      );

      blocTest<CanvasBloc, CanvasState>(
        'emits state with updated camera offset',
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        seed: () => const CanvasState(
          status: CanvasStatus.ready,
          canvasData: canvasData,
        ),
        act: (bloc) => bloc.add(const CameraPositionChanged(Offset(30, 40))),
        expect: () => [
          isA<CanvasState>().having(
            (s) => s.cameraPosition,
            'camera offset',
            equals(const Offset(30, 40)),
          ),
        ],
      );

      blocTest<CanvasBloc, CanvasState>(
        'preserves canvas data and zoom level',
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        seed: () => const CanvasState(
          status: CanvasStatus.ready,
          canvasData: canvasData,
          zoomLevel: 4,
        ),
        act: (bloc) => bloc.add(const CameraPositionChanged(Offset(100, 200))),
        expect: () => [
          isA<CanvasState>()
              .having((s) => s.canvasData, 'canvas data', equals(canvasData))
              .having((s) => s.zoomLevel, 'zoom level', equals(4)),
        ],
      );
    });
  });
}
