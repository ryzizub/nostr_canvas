import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:pixel_repository/pixel_repository.dart';

class MockPixelRepository extends Mock implements PixelRepository {}

class FakePixel extends Fake implements Pixel {}

void main() {
  group('CanvasBloc', () {
    late PixelRepository pixelRepository;

    setUpAll(() {
      registerFallbackValue(FakePixel());
    });

    setUp(() {
      pixelRepository = MockPixelRepository();
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

    group('PixelPlaced', () {
      const canvasData = CanvasData(width: 1000, height: 1000);
      const position = Position(100, 100);
      const color = Colors.orange;

      blocTest<CanvasBloc, CanvasState>(
        'does nothing when status is not ready',
        setUp: () {
          when(() => pixelRepository.placePixel(any()))
              .thenAnswer((_) async {});
        },
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(
          const PixelPlaced(position: position, color: color),
        ),
        expect: () => <CanvasState>[],
        verify: (_) {
          verifyNever(() => pixelRepository.placePixel(any()));
        },
      );

      blocTest<CanvasBloc, CanvasState>(
        'emits updated state with new pixel',
        setUp: () {
          when(() => pixelRepository.placePixel(any()))
              .thenAnswer((_) async {});
        },
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        seed: () => const CanvasState(
          status: CanvasStatus.ready,
          canvasData: canvasData,
        ),
        act: (bloc) => bloc.add(
          const PixelPlaced(position: position, color: color),
        ),
        expect: () => [
          isA<CanvasState>()
              .having((s) => s.status, 'status', CanvasStatus.ready)
              .having(
                (s) => s.canvasData!.pixels.length,
                'has one pixel',
                equals(1),
              )
              .having(
                (s) => s.canvasData!.getPixel(position)?.color,
                'pixel color',
                equals(color),
              ),
        ],
        verify: (_) {
          verify(() => pixelRepository.placePixel(any())).called(1);
        },
      );

      blocTest<CanvasBloc, CanvasState>(
        'preserves zoom and camera offset when placing pixel',
        setUp: () {
          when(() => pixelRepository.placePixel(any()))
              .thenAnswer((_) async {});
        },
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        seed: () => const CanvasState(
          status: CanvasStatus.ready,
          canvasData: canvasData,
          zoomLevel: 2,
          cameraOffset: Offset(10, 20),
        ),
        act: (bloc) => bloc.add(
          const PixelPlaced(position: position, color: color),
        ),
        expect: () => [
          isA<CanvasState>()
              .having((s) => s.zoomLevel, 'zoom level', equals(2))
              .having(
                (s) => s.cameraOffset,
                'camera offset',
                equals(const Offset(10, 20)),
              ),
        ],
      );

      blocTest<CanvasBloc, CanvasState>(
        'does not emit when repository throws',
        setUp: () {
          when(() => pixelRepository.placePixel(any())).thenThrow(
            Exception('Out of bounds'),
          );
        },
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        seed: () => const CanvasState(
          status: CanvasStatus.ready,
          canvasData: canvasData,
        ),
        act: (bloc) => bloc.add(
          const PixelPlaced(position: position, color: color),
        ),
        expect: () => <CanvasState>[],
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
          cameraOffset: Offset(50, 100),
        ),
        act: (bloc) => bloc.add(const ZoomChanged(3)),
        expect: () => [
          isA<CanvasState>()
              .having((s) => s.canvasData, 'canvas data', equals(canvasData))
              .having(
                (s) => s.cameraOffset,
                'camera offset',
                equals(const Offset(50, 100)),
              ),
        ],
      );
    });

    group('CanvasPanned', () {
      const canvasData = CanvasData(width: 1000, height: 1000);

      blocTest<CanvasBloc, CanvasState>(
        'does nothing when status is not ready',
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const CanvasPanned(Offset(10, 20))),
        expect: () => <CanvasState>[],
      );

      blocTest<CanvasBloc, CanvasState>(
        'emits state with updated camera offset',
        build: () => CanvasBloc(pixelRepository: pixelRepository),
        seed: () => const CanvasState(
          status: CanvasStatus.ready,
          canvasData: canvasData,
        ),
        act: (bloc) => bloc.add(const CanvasPanned(Offset(30, 40))),
        expect: () => [
          isA<CanvasState>().having(
            (s) => s.cameraOffset,
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
        act: (bloc) => bloc.add(const CanvasPanned(Offset(100, 200))),
        expect: () => [
          isA<CanvasState>()
              .having((s) => s.canvasData, 'canvas data', equals(canvasData))
              .having((s) => s.zoomLevel, 'zoom level', equals(4)),
        ],
      );
    });
  });
}
