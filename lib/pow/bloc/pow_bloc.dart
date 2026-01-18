import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nostr_canvas/pow/models/queued_pixel.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

part 'pow_event.dart';
part 'pow_state.dart';

class PowBloc extends Bloc<PowEvent, PowState> {
  PowBloc({
    required PixelRepository pixelRepository,
  }) : _pixelRepository = pixelRepository,
       super(const PowState()) {
    on<PowPlacePixelRequested>(_onPlacePixelRequested);
    on<PowPixelQueued>(_onPixelQueued);
    on<PowQueueItemRemoved>(_onQueueItemRemoved);
    on<PowQueueCleared>(_onQueueCleared);
    on<PowQueueRetried>(_onQueueRetried);
    on<PowQueueSkipped>(_onQueueSkipped);
    on<_PowProcessNextQueued>(_onProcessNextQueued);
    on<PowDismissed>(_onDismissed);
  }

  final PixelRepository _pixelRepository;

  void _onPixelQueued(
    PowPixelQueued event,
    Emitter<PowState> emit,
  ) {
    if (!state.canAddToQueue) return;

    final queuedPixel = QueuedPixel(
      position: event.position,
      color: event.color,
    );

    // Check for duplicate position - replace if exists
    final newQueue =
        state.queue.where((p) => p.position != event.position).toList()
          ..add(queuedPixel);

    emit(state.copyWith(queue: newQueue));

    // If idle, start processing
    if (state.status == PowStatus.idle) {
      add(const _PowProcessNextQueued());
    }
  }

  void _onQueueItemRemoved(
    PowQueueItemRemoved event,
    Emitter<PowState> emit,
  ) {
    final newQueue = state.queue.where((p) => p.id != event.pixelId).toList();
    emit(state.copyWith(queue: newQueue));
  }

  void _onQueueCleared(
    PowQueueCleared event,
    Emitter<PowState> emit,
  ) {
    emit(
      state.copyWith(
        queue: [],
        status: PowStatus.idle,
        currentPixel: () => null,
        progress: () => null,
      ),
    );
  }

  void _onQueueRetried(
    PowQueueRetried event,
    Emitter<PowState> emit,
  ) {
    if (state.currentPixel == null) return;

    // Reset to idle and reprocess current pixel
    emit(
      state.copyWith(
        status: PowStatus.idle,
        progress: () => null,
      ),
    );

    add(const _PowProcessNextQueued());
  }

  void _onQueueSkipped(
    PowQueueSkipped event,
    Emitter<PowState> emit,
  ) {
    // Clear current pixel and process next
    emit(
      state.copyWith(
        currentPixel: () => null,
        status: PowStatus.idle,
        progress: () => null,
      ),
    );

    if (state.hasQueuedPixels) {
      add(const _PowProcessNextQueued());
    }
  }

  Future<void> _onProcessNextQueued(
    _PowProcessNextQueued event,
    Emitter<PowState> emit,
  ) async {
    // If already processing or no items, do nothing
    if (state.status != PowStatus.idle) return;

    // Get next pixel from queue or use current (for retry)
    var pixelToProcess = state.currentPixel;
    var newQueue = state.queue;

    if (pixelToProcess == null && state.queue.isNotEmpty) {
      pixelToProcess = state.queue.first;
      newQueue = state.queue.sublist(1);
    }

    if (pixelToProcess == null) return;

    emit(
      state.copyWith(
        currentPixel: () => pixelToProcess,
        queue: newQueue,
        status: PowStatus.mining,
        progress: () => const PlacementProgress(phase: PlacementPhase.mining),
      ),
    );

    try {
      await emit.forEach<PowProgress>(
        _pixelRepository.placePixelWithProgress(
          pixelToProcess.position,
          pixelToProcess.color,
        ),
        onData: (progress) {
          return switch (progress) {
            PowMining(
              :final noncesAttempted,
              :final currentDifficulty,
              :final targetDifficulty,
              :final hashRate,
            ) =>
              state.copyWith(
                status: PowStatus.mining,
                progress: () => PlacementProgress(
                  phase: PlacementPhase.mining,
                  noncesAttempted: noncesAttempted,
                  currentDifficulty: currentDifficulty,
                  targetDifficulty: targetDifficulty,
                  hashRate: hashRate,
                ),
              ),
            PowComplete() => state.copyWith(
              status: PowStatus.sending,
              progress: () =>
                  const PlacementProgress(phase: PlacementPhase.sending),
            ),
            PowSending() => state.copyWith(
              status: PowStatus.sending,
              progress: () =>
                  const PlacementProgress(phase: PlacementPhase.sending),
            ),
            PowSuccess() => state.copyWith(
              status: PowStatus.idle,
              currentPixel: () => null,
              progress: () => null,
            ),
            PowError(:final message) => state.copyWith(
              status: PowStatus.error,
              progress: () => PlacementProgress(
                phase: PlacementPhase.error,
                errorMessage: message,
              ),
            ),
          };
        },
      );

      // On success, process next item if available
      if (state.status == PowStatus.idle && state.hasQueuedPixels) {
        add(const _PowProcessNextQueued());
      }
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: PowStatus.error,
          progress: () => PlacementProgress(
            phase: PlacementPhase.error,
            errorMessage: error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _onPlacePixelRequested(
    PowPlacePixelRequested event,
    Emitter<PowState> emit,
  ) async {
    // Legacy method - convert to queue-based approach
    add(PowPixelQueued(position: event.position, color: event.color));
  }

  void _onDismissed(
    PowDismissed event,
    Emitter<PowState> emit,
  ) {
    emit(
      state.copyWith(
        status: PowStatus.idle,
        currentPixel: () => null,
        progress: () => null,
      ),
    );
  }
}
