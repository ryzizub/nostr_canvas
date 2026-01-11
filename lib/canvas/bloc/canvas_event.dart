part of 'canvas_bloc.dart';

abstract class CanvasEvent extends Equatable {
  const CanvasEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped to place a pixel
class PixelPlaced extends CanvasEvent {
  const PixelPlaced({
    required this.position,
    required this.color,
  });

  final Position position;
  final Color color;

  @override
  List<Object?> get props => [position, color];
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

/// User selected a new color
class ColorChanged extends CanvasEvent {
  const ColorChanged(this.color);

  final Color color;

  @override
  List<Object?> get props => [color];
}
