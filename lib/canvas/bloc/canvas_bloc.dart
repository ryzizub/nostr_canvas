import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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

    final pixel = Pixel(
      position: event.position,
      color: event.color,
      timestamp: DateTime.now(),
    );

    try {
      await _pixelRepository.placePixel(pixel);

      final updatedCanvas = state.canvasData!.placePixel(pixel);

      emit(state.copyWith(canvasData: updatedCanvas, errorMessage: () => null));
    } on Exception catch (error) {
      emit(
        state.copyWith(
          errorMessage: error.toString,
          status: CanvasStatus.error,
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
