part of 'canvas_bloc.dart';

abstract class CanvasEvent extends Equatable {
  const CanvasEvent();

  @override
  List<Object?> get props => [];
}

/// Zoom level changed
class ZoomChanged extends CanvasEvent {
  const ZoomChanged(this.zoomLevel);

  final double zoomLevel;

  @override
  List<Object?> get props => [zoomLevel];
}

/// Camera position changed (absolute position)
class CameraPositionChanged extends CanvasEvent {
  const CameraPositionChanged(this.position);

  final Offset position;

  @override
  List<Object?> get props => [position];
}

/// Request to load canvas data
class CanvasLoadRequested extends CanvasEvent {
  const CanvasLoadRequested();
}

/// Grid visibility toggled
class GridToggled extends CanvasEvent {
  const GridToggled();
}
