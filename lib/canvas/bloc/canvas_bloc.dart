import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/data/models/models.dart';
import 'package:nostr_place/canvas/data/repositories/pixel_repository.dart';

part 'canvas_event.dart';
part 'canvas_state.dart';

class CanvasBloc extends Bloc<CanvasEvent, CanvasState> {
  CanvasBloc({
    required PixelRepository pixelRepository,
  }) : _pixelRepository = pixelRepository,
       super(const CanvasInitial()) {
    on<CanvasLoadRequested>(_onLoadRequested);
    on<PixelPlaced>(_onPixelPlaced);
    on<ZoomChanged>(_onZoomChanged);
    on<CanvasPanned>(_onCanvasPanned);
  }

  final PixelRepository _pixelRepository;

  Future<void> _onLoadRequested(
    CanvasLoadRequested event,
    Emitter<CanvasState> emit,
  ) async {
    emit(const CanvasLoading());

    try {
      final canvasData = await _pixelRepository.loadCanvas();
      emit(CanvasReady(canvasData: canvasData));
    } on Exception catch (error) {
      emit(CanvasError(error.toString()));
    }
  }

  Future<void> _onPixelPlaced(
    PixelPlaced event,
    Emitter<CanvasState> emit,
  ) async {
    if (state is! CanvasReady) return;

    final currentState = state as CanvasReady;

    final pixel = Pixel(
      position: event.position,
      color: event.color,
      timestamp: DateTime.now(),
    );

    try {
      await _pixelRepository.placePixel(pixel);

      final updatedCanvas = currentState.canvasData.placePixel(pixel);

      emit(currentState.copyWith(canvasData: updatedCanvas));
    } on Exception {
      // Silently fail - pixel just doesn't appear
      // Could emit error state or show snackbar in UI
    }
  }

  void _onZoomChanged(
    ZoomChanged event,
    Emitter<CanvasState> emit,
  ) {
    if (state is! CanvasReady) return;

    final currentState = state as CanvasReady;
    emit(currentState.copyWith(zoomLevel: event.zoomLevel));
  }

  void _onCanvasPanned(
    CanvasPanned event,
    Emitter<CanvasState> emit,
  ) {
    if (state is! CanvasReady) return;

    final currentState = state as CanvasReady;
    emit(currentState.copyWith(cameraOffset: event.offset));
  }
}
