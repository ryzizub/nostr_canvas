import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr_canvas/pow/pow.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

class MockPixelRepository extends Mock implements PixelRepository {}

void main() {
  group('PowBloc', () {
    late PixelRepository pixelRepository;

    setUpAll(() {
      registerFallbackValue(const Position(0, 0));
      registerFallbackValue(Colors.black);
    });

    setUp(() {
      pixelRepository = MockPixelRepository();
    });

    test('initial state is idle with empty queue', () {
      final bloc = PowBloc(pixelRepository: pixelRepository);
      expect(bloc.state.status, equals(PowStatus.idle));
      expect(bloc.state.queue, isEmpty);
      expect(bloc.state.currentPixel, isNull);
      expect(bloc.state.progress, isNull);
    });

    group('PowPixelQueued', () {
      blocTest<PowBloc, PowState>(
        'adds pixel to queue and starts processing when idle',
        setUp: () {
          when(
            () => pixelRepository.placePixelWithProgress(any(), any()),
          ).thenAnswer(
            (_) => Stream.value(const PowSuccess(eventId: 'test-event-id')),
          );
        },
        build: () => PowBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(
          const PowPixelQueued(position: Position(5, 10), color: Colors.red),
        ),
        expect: () => [
          // First: pixel added to queue
          isA<PowState>()
              .having((s) => s.queue.length, 'queue length', 1)
              .having(
                (s) => s.queue.first.position,
                'position',
                const Position(5, 10),
              )
              .having((s) => s.queue.first.color, 'color', Colors.red),
          // Then: processing starts - pixel moved to currentPixel
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.mining)
              .having((s) => s.currentPixel, 'currentPixel', isNotNull)
              .having((s) => s.queue, 'queue', isEmpty),
          // Finally: success - back to idle
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.idle)
              .having((s) => s.currentPixel, 'currentPixel', isNull),
        ],
      );

      blocTest<PowBloc, PowState>(
        'queues multiple pixels',
        setUp: () {
          when(
            () => pixelRepository.placePixelWithProgress(any(), any()),
          ).thenAnswer(
            (_) async* {
              // Slow stream to allow multiple pixels to queue
              await Future<void>.delayed(const Duration(milliseconds: 100));
              yield const PowSuccess(eventId: 'test-event-id');
            },
          );
        },
        build: () => PowBloc(pixelRepository: pixelRepository),
        act: (bloc) async {
          bloc
            ..add(
              const PowPixelQueued(position: Position(0, 0), color: Colors.red),
            )
            ..add(
              const PowPixelQueued(
                position: Position(1, 1),
                color: Colors.blue,
              ),
            )
            ..add(
              const PowPixelQueued(
                position: Position(2, 2),
                color: Colors.green,
              ),
            );
          // Wait for processing to complete
          await Future<void>.delayed(const Duration(milliseconds: 500));
        },
        verify: (bloc) {
          // All pixels should be processed
          expect(bloc.state.status, equals(PowStatus.idle));
          expect(bloc.state.queue, isEmpty);
          expect(bloc.state.currentPixel, isNull);
        },
      );

      blocTest<PowBloc, PowState>(
        'replaces pixel at same position in queue',
        build: () => PowBloc(pixelRepository: pixelRepository),
        seed: () => PowState(
          status: PowStatus.mining,
          currentPixel: QueuedPixel(
            position: const Position(0, 0),
            color: Colors.white,
          ),
          queue: [
            QueuedPixel(position: const Position(5, 5), color: Colors.red),
          ],
        ),
        act: (bloc) => bloc.add(
          const PowPixelQueued(position: Position(5, 5), color: Colors.blue),
        ),
        expect: () => [
          isA<PowState>()
              .having((s) => s.queue.length, 'queue length', 1)
              .having(
                (s) => s.queue.first.color,
                'replaced color',
                Colors.blue,
              ),
        ],
      );

      blocTest<PowBloc, PowState>(
        'does not add when queue is full',
        build: () => PowBloc(pixelRepository: pixelRepository),
        seed: () => PowState(
          status: PowStatus.mining,
          currentPixel: QueuedPixel(
            position: const Position(0, 0),
            color: Colors.white,
          ),
          queue: List.generate(
            maxQueueSize,
            (i) => QueuedPixel(
              position: Position(i, i),
              color: Colors.red,
            ),
          ),
        ),
        act: (bloc) => bloc.add(
          const PowPixelQueued(position: Position(99, 99), color: Colors.blue),
        ),
        expect: () => <PowState>[],
      );
    });

    group('PowQueueItemRemoved', () {
      blocTest<PowBloc, PowState>(
        'removes specific pixel from queue by id',
        build: () => PowBloc(pixelRepository: pixelRepository),
        seed: () {
          final pixel1 = QueuedPixel(
            position: const Position(1, 1),
            color: Colors.red,
          );
          final pixel2 = QueuedPixel(
            position: const Position(2, 2),
            color: Colors.blue,
          );
          return PowState(queue: [pixel1, pixel2]);
        },
        act: (bloc) {
          final pixelId = bloc.state.queue.first.id;
          bloc.add(PowQueueItemRemoved(pixelId: pixelId));
        },
        expect: () => [
          isA<PowState>()
              .having((s) => s.queue.length, 'queue length', 1)
              .having(
                (s) => s.queue.first.position,
                'remaining position',
                const Position(2, 2),
              ),
        ],
      );
    });

    group('PowQueueCleared', () {
      blocTest<PowBloc, PowState>(
        'clears entire queue and resets state',
        build: () => PowBloc(pixelRepository: pixelRepository),
        seed: () => PowState(
          status: PowStatus.mining,
          currentPixel: QueuedPixel(
            position: const Position(0, 0),
            color: Colors.white,
          ),
          queue: [
            QueuedPixel(position: const Position(1, 1), color: Colors.red),
            QueuedPixel(position: const Position(2, 2), color: Colors.blue),
          ],
          progress: const PlacementProgress(phase: PlacementPhase.mining),
        ),
        act: (bloc) => bloc.add(const PowQueueCleared()),
        expect: () => [
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.idle)
              .having((s) => s.queue, 'queue', isEmpty)
              .having((s) => s.currentPixel, 'currentPixel', isNull)
              .having((s) => s.progress, 'progress', isNull),
        ],
      );
    });

    group('PowQueueSkipped', () {
      blocTest<PowBloc, PowState>(
        'skips current pixel and processes next',
        setUp: () {
          when(
            () => pixelRepository.placePixelWithProgress(any(), any()),
          ).thenAnswer(
            (_) => Stream.value(const PowSuccess(eventId: 'test-event-id')),
          );
        },
        build: () => PowBloc(pixelRepository: pixelRepository),
        seed: () => PowState(
          status: PowStatus.error,
          currentPixel: QueuedPixel(
            position: const Position(0, 0),
            color: Colors.white,
          ),
          queue: [
            QueuedPixel(position: const Position(1, 1), color: Colors.red),
          ],
          progress: const PlacementProgress(
            phase: PlacementPhase.error,
            errorMessage: 'Test error',
          ),
        ),
        act: (bloc) => bloc.add(const PowQueueSkipped()),
        expect: () => [
          // First: current pixel cleared, status idle
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.idle)
              .having((s) => s.currentPixel, 'currentPixel', isNull),
          // Then: next pixel starts processing
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.mining)
              .having((s) => s.currentPixel, 'currentPixel', isNotNull)
              .having(
                (s) => s.currentPixel?.position,
                'position',
                const Position(1, 1),
              ),
          // Finally: success
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.idle)
              .having((s) => s.currentPixel, 'currentPixel', isNull),
        ],
      );

      blocTest<PowBloc, PowState>(
        'goes idle when no more pixels in queue',
        build: () => PowBloc(pixelRepository: pixelRepository),
        seed: () => PowState(
          status: PowStatus.error,
          currentPixel: QueuedPixel(
            position: const Position(0, 0),
            color: Colors.white,
          ),
        ),
        act: (bloc) => bloc.add(const PowQueueSkipped()),
        expect: () => [
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.idle)
              .having((s) => s.currentPixel, 'currentPixel', isNull)
              .having((s) => s.queue, 'queue', isEmpty),
        ],
      );
    });

    group('PowQueueRetried', () {
      blocTest<PowBloc, PowState>(
        'retries current pixel after error',
        setUp: () {
          when(
            () => pixelRepository.placePixelWithProgress(any(), any()),
          ).thenAnswer(
            (_) => Stream.value(const PowSuccess(eventId: 'test-event-id')),
          );
        },
        build: () => PowBloc(pixelRepository: pixelRepository),
        seed: () => PowState(
          status: PowStatus.error,
          currentPixel: QueuedPixel(
            position: const Position(5, 5),
            color: Colors.green,
          ),
          progress: const PlacementProgress(
            phase: PlacementPhase.error,
            errorMessage: 'Connection failed',
          ),
        ),
        act: (bloc) => bloc.add(const PowQueueRetried()),
        expect: () => [
          // First: reset to idle
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.idle)
              .having((s) => s.progress, 'progress', isNull)
              .having((s) => s.currentPixel, 'currentPixel', isNotNull),
          // Then: retry starts
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.mining)
              .having(
                (s) => s.currentPixel?.position,
                'position',
                const Position(5, 5),
              ),
          // Finally: success
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.idle)
              .having((s) => s.currentPixel, 'currentPixel', isNull),
        ],
      );

      blocTest<PowBloc, PowState>(
        'does nothing when no current pixel',
        build: () => PowBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(const PowQueueRetried()),
        expect: () => <PowState>[],
      );
    });

    group('PowDismissed', () {
      blocTest<PowBloc, PowState>(
        'resets state to idle',
        build: () => PowBloc(pixelRepository: pixelRepository),
        seed: () => PowState(
          status: PowStatus.error,
          currentPixel: QueuedPixel(
            position: const Position(0, 0),
            color: Colors.white,
          ),
          progress: const PlacementProgress(
            phase: PlacementPhase.error,
            errorMessage: 'Error',
          ),
        ),
        act: (bloc) => bloc.add(const PowDismissed()),
        expect: () => [
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.idle)
              .having((s) => s.currentPixel, 'currentPixel', isNull)
              .having((s) => s.progress, 'progress', isNull),
        ],
      );
    });

    group('Mining progress', () {
      blocTest<PowBloc, PowState>(
        'emits mining progress updates',
        setUp: () {
          when(
            () => pixelRepository.placePixelWithProgress(any(), any()),
          ).thenAnswer(
            (_) => Stream.fromIterable([
              const PowMining(
                noncesAttempted: 1000,
                currentDifficulty: 8,
                targetDifficulty: 16,
                elapsedMilliseconds: 20,
              ),
              const PowMining(
                noncesAttempted: 5000,
                currentDifficulty: 12,
                targetDifficulty: 16,
                elapsedMilliseconds: 100,
              ),
              const PowComplete(
                nonce: 'abc123',
                achievedDifficulty: 16,
                targetDifficulty: 16,
                elapsedMilliseconds: 150,
                createdAt: 1234567890,
              ),
              const PowSending(),
              const PowSuccess(eventId: 'test-event-id'),
            ]),
          );
        },
        build: () => PowBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(
          const PowPixelQueued(position: Position(0, 0), color: Colors.red),
        ),
        expect: () => [
          // Pixel queued
          isA<PowState>().having((s) => s.queue.length, 'queue length', 1),
          // Processing starts
          isA<PowState>().having((s) => s.status, 'status', PowStatus.mining),
          // Mining progress 1
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.mining)
              .having(
                (s) => s.progress?.noncesAttempted,
                'nonces',
                1000,
              ),
          // Mining progress 2
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.mining)
              .having(
                (s) => s.progress?.noncesAttempted,
                'nonces',
                5000,
              ),
          // Mining complete -> sending
          isA<PowState>().having((s) => s.status, 'status', PowStatus.sending),
          // Success
          isA<PowState>().having((s) => s.status, 'status', PowStatus.idle),
        ],
      );

      blocTest<PowBloc, PowState>(
        'handles error during mining',
        setUp: () {
          when(
            () => pixelRepository.placePixelWithProgress(any(), any()),
          ).thenAnswer(
            (_) => Stream.fromIterable([
              const PowMining(
                noncesAttempted: 1000,
                currentDifficulty: 8,
                targetDifficulty: 16,
                elapsedMilliseconds: 20,
              ),
              const PowError(message: 'Mining failed'),
            ]),
          );
        },
        build: () => PowBloc(pixelRepository: pixelRepository),
        act: (bloc) => bloc.add(
          const PowPixelQueued(position: Position(0, 0), color: Colors.red),
        ),
        expect: () => [
          // Pixel queued
          isA<PowState>().having((s) => s.queue.length, 'queue length', 1),
          // Processing starts
          isA<PowState>().having((s) => s.status, 'status', PowStatus.mining),
          // Mining progress
          isA<PowState>().having((s) => s.status, 'status', PowStatus.mining),
          // Error
          isA<PowState>()
              .having((s) => s.status, 'status', PowStatus.error)
              .having(
                (s) => s.progress?.errorMessage,
                'error message',
                'Mining failed',
              )
              .having((s) => s.currentPixel, 'currentPixel', isNotNull),
        ],
      );
    });

    group('PowState', () {
      test('hasQueuedPixels returns true when queue is not empty', () {
        final state = PowState(
          queue: [
            QueuedPixel(position: const Position(0, 0), color: Colors.red),
          ],
        );
        expect(state.hasQueuedPixels, isTrue);
      });

      test('hasQueuedPixels returns false when queue is empty', () {
        const state = PowState();
        expect(state.hasQueuedPixels, isFalse);
      });

      test('queueLength returns correct count', () {
        final state = PowState(
          queue: [
            QueuedPixel(position: const Position(0, 0), color: Colors.red),
            QueuedPixel(position: const Position(1, 1), color: Colors.blue),
          ],
        );
        expect(state.queueLength, equals(2));
      });

      test('canAddToQueue returns true when under limit', () {
        final state = PowState(
          queue: List.generate(
            maxQueueSize - 1,
            (i) => QueuedPixel(
              position: Position(i, i),
              color: Colors.red,
            ),
          ),
        );
        expect(state.canAddToQueue, isTrue);
      });

      test('canAddToQueue returns false when at limit', () {
        final state = PowState(
          queue: List.generate(
            maxQueueSize,
            (i) => QueuedPixel(
              position: Position(i, i),
              color: Colors.red,
            ),
          ),
        );
        expect(state.canAddToQueue, isFalse);
      });
    });
  });
}
