part of 'canvas_bloc.dart';

enum CanvasStatus { initial, loading, ready, error }

/// Phase of pixel placement operation.
enum PlacementPhase { mining, sending, success, error }

/// Progress of a pixel placement operation.
class PlacementProgress extends Equatable {
  const PlacementProgress({
    required this.phase,
    this.noncesAttempted = 0,
    this.currentDifficulty = 0,
    this.targetDifficulty = 0,
    this.hashRate = 0.0,
    this.errorMessage,
  });

  final PlacementPhase phase;
  final int noncesAttempted;
  final int currentDifficulty;
  final int targetDifficulty;
  final double hashRate;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    phase,
    noncesAttempted,
    currentDifficulty,
    targetDifficulty,
    hashRate,
    errorMessage,
  ];
}

class CanvasState extends Equatable {
  const CanvasState({
    this.status = CanvasStatus.initial,
    this.canvasData,
    this.zoomLevel = 1.0,
    this.cameraPosition = Offset.zero,
    this.selectedColor = Colors.orange,
    this.errorMessage,
    this.placementProgress,
  });

  final CanvasStatus status;
  final CanvasData? canvasData;
  final double zoomLevel;
  final Offset cameraPosition;
  final Color selectedColor;
  final String? errorMessage;
  final PlacementProgress? placementProgress;

  @override
  List<Object?> get props => [
    status,
    canvasData,
    zoomLevel,
    cameraPosition,
    selectedColor,
    errorMessage,
    placementProgress,
  ];

  CanvasState copyWith({
    CanvasStatus? status,
    CanvasData? canvasData,
    double? zoomLevel,
    Offset? cameraPosition,
    Color? selectedColor,
    String? Function()? errorMessage,
    PlacementProgress? Function()? placementProgress,
  }) {
    return CanvasState(
      status: status ?? this.status,
      canvasData: canvasData ?? this.canvasData,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      selectedColor: selectedColor ?? this.selectedColor,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      placementProgress: placementProgress != null
          ? placementProgress()
          : this.placementProgress,
    );
  }
}
