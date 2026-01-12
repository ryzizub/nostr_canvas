part of 'canvas_bloc.dart';

enum CanvasStatus { initial, loading, ready, error }

class CanvasState extends Equatable {
  const CanvasState({
    this.status = CanvasStatus.initial,
    this.canvasData,
    this.zoomLevel = 1.0,
    this.cameraPosition = Offset.zero,
    this.errorMessage,
    this.gridEnabled = true,
  });

  final CanvasStatus status;
  final CanvasData? canvasData;
  final double zoomLevel;
  final Offset cameraPosition;
  final String? errorMessage;
  final bool gridEnabled;

  @override
  List<Object?> get props => [
    status,
    canvasData,
    zoomLevel,
    cameraPosition,
    errorMessage,
    gridEnabled,
  ];

  CanvasState copyWith({
    CanvasStatus? status,
    CanvasData? canvasData,
    double? zoomLevel,
    Offset? cameraPosition,
    String? Function()? errorMessage,
    bool? gridEnabled,
  }) {
    return CanvasState(
      status: status ?? this.status,
      canvasData: canvasData ?? this.canvasData,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      gridEnabled: gridEnabled ?? this.gridEnabled,
    );
  }
}
