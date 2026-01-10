/// Constants for the canvas game.
abstract final class CanvasConstants {
  /// Size of each pixel in world units.
  /// All grid coordinates are multiplied by this to get world position.
  static const double tileSize = 10;

  /// Minimum allowed zoom level.
  static const double minZoom = 0.1;

  /// Maximum allowed zoom level.
  static const double maxZoom = 100;

  /// Zoom multiplier when zooming in via buttons.
  static const double zoomInFactor = 1.2;

  /// Zoom multiplier when scrolling to zoom in.
  static const double scrollZoomInFactor = 1.1;

  /// Zoom multiplier when scrolling to zoom out.
  static const double scrollZoomOutFactor = 0.9;

  /// Minimum drag distance to start panning (distinguishes taps from drags).
  static const double panThreshold = 5;

  /// Target number of pixels to show vertically when auto-fitting zoom.
  static const int targetPixelsToShow = 50;

  /// Padding multiplier for initial zoom calculation.
  static const double zoomPaddingFactor = 0.9;
}
