import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

part 'canvas_event.dart';
part 'canvas_state.dart';

class CanvasBloc extends Bloc<CanvasEvent, CanvasState> {
  CanvasBloc({
    required PixelRepository pixelRepository,
  }) : _pixelRepository = pixelRepository,
       super(const CanvasState()) {
    on<CanvasLoadRequested>(_onLoadRequested);
    on<PixelPlaced>(_onPixelPlaced);
    on<ZoomChanged>(_onZoomChanged);
    on<CameraPositionChanged>(_onCameraPositionChanged);
  }

  final PixelRepository _pixelRepository;

  Future<void> _onLoadRequested(
    CanvasLoadRequested event,
    Emitter<CanvasState> emit,
  ) async {
    emit(state.copyWith(status: CanvasStatus.loading));

    try {
      final canvasData = await _pixelRepository.loadCanvas();

      emit(
        state.copyWith(
          status: CanvasStatus.ready,
          canvasData: canvasData,
          errorMessage: () => null,
        ),
      );

      await emit.forEach<CanvasData>(
        _pixelRepository.canvasUpdates,
        onData: (canvasData) => state.copyWith(canvasData: canvasData),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: CanvasStatus.error,
          errorMessage: error.toString,
        ),
      );
    }
  }

  Future<void> _onPixelPlaced(
    PixelPlaced event,
    Emitter<CanvasState> emit,
  ) async {
    if (state.status != CanvasStatus.ready) return;
    if (state.placementProgress != null) return; // Already placing

    emit(
      state.copyWith(
        placementProgress: () => const PlacementProgress(
          phase: PlacementPhase.mining,
        ),
      ),
    );

    try {
      await emit.forEach<PowProgress>(
        _pixelRepository.placePixelWithProgress(event.position, event.color),
        onData: (progress) {
          return switch (progress) {
            PowMining(
              :final noncesAttempted,
              :final currentDifficulty,
              :final targetDifficulty,
              :final hashRate,
            ) =>
              state.copyWith(
                placementProgress: () => PlacementProgress(
                  phase: PlacementPhase.mining,
                  noncesAttempted: noncesAttempted,
                  currentDifficulty: currentDifficulty,
                  targetDifficulty: targetDifficulty,
                  hashRate: hashRate,
                ),
              ),
            PowComplete() => state.copyWith(
              placementProgress: () => const PlacementProgress(
                phase: PlacementPhase.sending,
              ),
            ),
            PowSending() => state.copyWith(
              placementProgress: () => const PlacementProgress(
                phase: PlacementPhase.sending,
              ),
            ),
            PowSuccess() => state.copyWith(
              placementProgress: () => null,
            ),
            PowError(:final message) => state.copyWith(
              placementProgress: () => PlacementProgress(
                phase: PlacementPhase.error,
                errorMessage: message,
              ),
            ),
          };
        },
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          placementProgress: () => PlacementProgress(
            phase: PlacementPhase.error,
            errorMessage: error.toString(),
          ),
        ),
      );
    }
  }

  void _onZoomChanged(
    ZoomChanged event,
    Emitter<CanvasState> emit,
  ) {
    if (state.status != CanvasStatus.ready) return;

    emit(state.copyWith(zoomLevel: event.zoomLevel));
  }

  void _onCameraPositionChanged(
    CameraPositionChanged event,
    Emitter<CanvasState> emit,
  ) {
    if (state.status != CanvasStatus.ready) return;

    emit(state.copyWith(cameraPosition: event.position));
  }
}
