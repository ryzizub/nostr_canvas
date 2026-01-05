import 'package:nostr_place/canvas/data/models/models.dart';

/// Repository for pixel data storage and retrieval.
/// Currently in-memory, designed for future Nostr integration.
abstract class PixelRepository {
  Future<CanvasData> loadCanvas();
  Future<void> placePixel(Pixel pixel);
  Future<void> clearCanvas();
}

/// In-memory implementation for local testing.
class InMemoryPixelRepository implements PixelRepository {
  InMemoryPixelRepository({
    int canvasWidth = 1000,
    int canvasHeight = 1000,
  }) : _canvasData = CanvasData(
         width: canvasWidth,
         height: canvasHeight,
       );

  CanvasData _canvasData;

  @override
  Future<CanvasData> loadCanvas() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _canvasData;
  }

  @override
  Future<void> placePixel(Pixel pixel) async {
    // Validate bounds
    if (pixel.position.x < 0 ||
        pixel.position.x >= _canvasData.width ||
        pixel.position.y < 0 ||
        pixel.position.y >= _canvasData.height) {
      throw Exception('Pixel position out of bounds');
    }

    _canvasData = _canvasData.placePixel(pixel);
  }

  @override
  Future<void> clearCanvas() async {
    _canvasData = CanvasData(
      width: _canvasData.width,
      height: _canvasData.height,
    );
  }
}
