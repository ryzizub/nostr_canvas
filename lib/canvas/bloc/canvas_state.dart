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
    this.inspectModeEnabled = false,
    this.inspectedPixel,
  });

  final CanvasStatus status;
  final CanvasData? canvasData;
  final double zoomLevel;
  final Offset cameraPosition;
  final String? errorMessage;
  final bool gridEnabled;
  final bool inspectModeEnabled;
  final Pixel? inspectedPixel;

  @override
  List<Object?> get props => [
    status,
    canvasData,
    zoomLevel,
    cameraPosition,
    errorMessage,
    gridEnabled,
    inspectModeEnabled,
    inspectedPixel,
  ];

  CanvasState copyWith({
    CanvasStatus? status,
    CanvasData? canvasData,
    double? zoomLevel,
    Offset? cameraPosition,
    String? Function()? errorMessage,
    bool? gridEnabled,
    bool? inspectModeEnabled,
    Pixel? Function()? inspectedPixel,
  }) {
    return CanvasState(
      status: status ?? this.status,
      canvasData: canvasData ?? this.canvasData,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      gridEnabled: gridEnabled ?? this.gridEnabled,
      inspectModeEnabled: inspectModeEnabled ?? this.inspectModeEnabled,
      inspectedPixel: inspectedPixel != null
          ? inspectedPixel()
          : this.inspectedPixel,
    );
  }
}
