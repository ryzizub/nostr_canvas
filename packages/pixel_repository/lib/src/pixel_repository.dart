import 'dart:async';
import 'dart:ui';

import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/src/models/canvas_data.dart';
import 'package:pixel_repository/src/models/pixel.dart';
import 'package:pixel_repository/src/models/position.dart';

/// Pixel event kind for the canvas.
const int pixelEventKind = 9549;

/// Nostr-backed pixel repository.
///
/// Publishes pixels as Nostr events and subscribes to updates from the relay.
class PixelRepository {
  /// Creates a PixelRepository with the given client.
  PixelRepository({
    required NostrClient nostrClient,
    required this.canvasWidth,
    required this.canvasHeight,
  }) : _nostrClient = nostrClient;

  final NostrClient _nostrClient;

  /// Canvas width.
  final int canvasWidth;

  /// Canvas height.
  final int canvasHeight;

  late CanvasData _canvasData;
  String? _subscriptionId;

  final _canvasUpdatesController = StreamController<CanvasData>.broadcast();

  /// Stream of canvas updates (emitted after each pixel change).
  Stream<CanvasData> get canvasUpdates => _canvasUpdatesController.stream;

  /// Connection state stream from the underlying client.
  Stream<ConnectionState> get connectionState => _nostrClient.connectionState;

  Future<CanvasData> loadCanvas() async {
    _canvasData = CanvasData(width: canvasWidth, height: canvasHeight);

    // Subscribe to pixel events
    _subscriptionId = _nostrClient.subscribe([
      Filter(kinds: [pixelEventKind]),
    ]);

    // Listen to incoming events
    _nostrClient.events.listen(_handleEvent);

    return _canvasData;
  }

  Future<void> placePixel(Position position, Color color) async {
    // Validate bounds
    if (position.x < 0 ||
        position.x >= canvasWidth ||
        position.y < 0 ||
        position.y >= canvasHeight) {
      throw Exception('Pixel position out of bounds');
    }

    // Convert color to hex (RGB, no # prefix)
    final argb = color.toARGB32();
    final rgb = argb & 0xFFFFFF;
    final colorHex = rgb.toRadixString(16).padLeft(6, '0');

    await _nostrClient.publish(
      kind: pixelEventKind,
      tags: [
        ['x', position.x.toString()],
        ['y', position.y.toString()],
        ['color', colorHex],
      ],
      content: '',
    );
  }

  /// Place a pixel with progress reporting.
  ///
  /// Returns a stream of [PowProgress] updates during mining and sending.
  Stream<PowProgress> placePixelWithProgress(Position position, Color color) {
    // Validate bounds
    if (position.x < 0 ||
        position.x >= canvasWidth ||
        position.y < 0 ||
        position.y >= canvasHeight) {
      return Stream.value(
        const PowError(message: 'Pixel position out of bounds'),
      );
    }

    // Convert color to hex (RGB, no # prefix)
    final argb = color.toARGB32();
    final rgb = argb & 0xFFFFFF;
    final colorHex = rgb.toRadixString(16).padLeft(6, '0');

    return _nostrClient.publishWithProgress(
      kind: pixelEventKind,
      tags: [
        ['x', position.x.toString()],
        ['y', position.y.toString()],
        ['color', colorHex],
      ],
      content: '',
    );
  }

  /// Dispose resources.
  Future<void> dispose() async {
    if (_subscriptionId != null) {
      _nostrClient.unsubscribe(_subscriptionId!);
    }
    await _canvasUpdatesController.close();
  }

  void _handleEvent(Event event) {
    if (event.kind != pixelEventKind) return;

    try {
      final pixel = _parsePixelEvent(event);
      if (pixel != null) {
        _canvasData = _canvasData.placePixel(pixel);
        _canvasUpdatesController.add(_canvasData);
      }
    } on Object {
      // Skip malformed events
    }
  }

  /// Assist

  Pixel? _parsePixelEvent(Event event) {
    int? x;
    int? y;
    String? colorHex;

    for (final tag in event.tags) {
      if (tag.length >= 2) {
        if (tag[0] == 'x') {
          x = int.tryParse(tag[1]);
        } else if (tag[0] == 'y') {
          y = int.tryParse(tag[1]);
        } else if (tag[0] == 'color') {
          colorHex = tag[1];
        }
      }
    }

    if (x == null || y == null || colorHex == null) return null;
    if (x < 0 || x >= canvasWidth || y < 0 || y >= canvasHeight) return null;

    // Parse hex color (e.g., "ff9800")
    final cleanHex = colorHex.replaceFirst('#', '');
    final colorValue = int.tryParse(cleanHex, radix: 16);
    if (colorValue == null) return null;

    // Convert RGB to ARGB (add full opacity)
    final argbColor = 0xFF000000 | colorValue;

    return Pixel(
      position: Position(x, y),
      color: Color(argbColor),
      timestamp: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }
}
