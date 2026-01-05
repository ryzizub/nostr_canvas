part of 'canvas_bloc.dart';

abstract class CanvasState extends Equatable {
  const CanvasState();

  @override
  List<Object?> get props => [];
}

class CanvasInitial extends CanvasState {
  const CanvasInitial();
}

class CanvasLoading extends CanvasState {
  const CanvasLoading();
}

class CanvasReady extends CanvasState {
  const CanvasReady({
    required this.canvasData,
    this.zoomLevel = 1.0,
    this.cameraOffset = Offset.zero,
  });

  final CanvasData canvasData;
  final double zoomLevel;
  final Offset cameraOffset;

  @override
  List<Object?> get props => [canvasData, zoomLevel, cameraOffset];

  CanvasReady copyWith({
    CanvasData? canvasData,
    double? zoomLevel,
    Offset? cameraOffset,
  }) {
    return CanvasReady(
      canvasData: canvasData ?? this.canvasData,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      cameraOffset: cameraOffset ?? this.cameraOffset,
    );
  }
}

class CanvasError extends CanvasState {
  const CanvasError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
