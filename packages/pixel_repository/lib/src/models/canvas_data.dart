import 'package:equatable/equatable.dart';
import 'package:pixel_repository/src/models/pixel.dart';
import 'package:pixel_repository/src/models/position.dart';

/// Immutable representation of canvas state.
class CanvasData extends Equatable {
  const CanvasData({
    required this.width,
    required this.height,
    this.pixels = const {},
  });

  final int width;
  final int height;

  /// Sparse map: only stores non-white pixels
  /// Key: "x,y" string for efficient lookup
  final Map<String, Pixel> pixels;

  static String _positionKey(Position pos) => '${pos.x},${pos.y}';

  /// Get pixel at position, returns null if white/empty
  Pixel? getPixel(Position position) {
    return pixels[_positionKey(position)];
  }

  /// Create new CanvasData with pixel placed
  CanvasData placePixel(Pixel pixel) {
    final newPixels = Map<String, Pixel>.from(pixels);
    newPixels[_positionKey(pixel.position)] = pixel;

    return CanvasData(
      width: width,
      height: height,
      pixels: newPixels,
    );
  }

  @override
  List<Object?> get props => [width, height, pixels];
}
