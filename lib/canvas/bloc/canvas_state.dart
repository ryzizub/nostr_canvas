part of 'canvas_bloc.dart';

enum CanvasStatus { initial, loading, ready, error }

class CanvasState extends Equatable {
  const CanvasState({
    this.status = CanvasStatus.initial,
    this.canvasData,
    this.zoomLevel = 1.0,
    this.cameraOffset = Offset.zero,
    this.errorMessage,
  });

  final CanvasStatus status;
  final CanvasData? canvasData;
  final double zoomLevel;
  final Offset cameraOffset;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        status,
        canvasData,
        zoomLevel,
        cameraOffset,
        errorMessage,
      ];

  CanvasState copyWith({
    CanvasStatus? status,
    CanvasData? canvasData,
    double? zoomLevel,
    Offset? cameraOffset,
    String? errorMessage,
  }) {
    return CanvasState(
      status: status ?? this.status,
      canvasData: canvasData ?? this.canvasData,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      cameraOffset: cameraOffset ?? this.cameraOffset,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
