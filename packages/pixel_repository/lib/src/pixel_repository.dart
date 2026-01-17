import 'dart:async' show StreamController, StreamSubscription, unawaited;
import 'dart:ui';

import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/src/models/canvas_data.dart';
import 'package:pixel_repository/src/models/pixel.dart';
import 'package:pixel_repository/src/models/position.dart';

/// Pixel event kind for the canvas.
const int pixelEventKind = 9549;

/// Nostr-backed pixel repository.
///
/// Publishes pixels as Nostr events and subscribes to updates from relays.
class PixelRepository {
  /// Creates a PixelRepository with a shared [RelayPool].
  ///
  /// The pool is shared and its lifecycle is managed externally.
  PixelRepository({
    required this.canvasWidth,
    required this.canvasHeight,
    required RelayPool relayPool,
  }) : _relayPool = relayPool;

  final RelayPool _relayPool;

  /// Canvas width.
  final int canvasWidth;

  /// Canvas height.
  final int canvasHeight;

  CanvasData? _canvasData;
  Map<String, String>? _subscriptionIds;
  StreamSubscription<Event>? _eventSubscription;

  final _canvasUpdatesController = StreamController<CanvasData>.broadcast();

  /// Stream of canvas updates (emitted after each pixel change).
  Stream<CanvasData> get canvasUpdates => _canvasUpdatesController.stream;

  /// Whether the pool is initialized and ready for operations.
  bool get hasClient => _relayPool.isInitialized;

  /// The relay pool.
  RelayPool get pool => _relayPool;

  /// Pool state stream from the underlying relay pool.
  Stream<RelayPoolState> get poolState => _relayPool.poolState;

  /// Current pool state.
  RelayPoolState get currentPoolState => _relayPool.currentState;

  /// Clear canvas data and reset state.
  ///
  /// Called on logout to clear all data. Does not close stream controllers.
  /// Does NOT clear the pool reference (pool lifecycle is managed externally).
  void clear() {
    // Unsubscribe from relays if connected
    if (_subscriptionIds != null && _relayPool.isInitialized) {
      _relayPool.unsubscribe(_subscriptionIds!);
      _subscriptionIds = null;
    }

    // Cancel event listener
    if (_eventSubscription != null) {
      unawaited(_eventSubscription!.cancel());
      _eventSubscription = null;
    }

    // Reset canvas data
    _canvasData = null;
  }

  Future<CanvasData> loadCanvas() async {
    if (!_relayPool.isInitialized) {
      throw StateError('RelayPool not initialized.');
    }

    _canvasData = CanvasData(width: canvasWidth, height: canvasHeight);

    // Subscribe to pixel events on all connected relays
    _subscriptionIds = _relayPool.subscribe([
      Filter(kinds: [pixelEventKind]),
    ]);

    // Listen to incoming events (deduplicated by RelayPool)
    _eventSubscription = _relayPool.events.listen(_handleEvent);

    return _canvasData!;
  }

  Future<void> placePixel(Position position, Color color) async {
    if (!_relayPool.isInitialized) {
      throw StateError('RelayPool not initialized.');
    }

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

    await _relayPool.publish(
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
    if (!_relayPool.isInitialized) {
      return Stream.value(
        const PowError(message: 'Not connected. Please log in first.'),
      );
    }

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

    return _relayPool.publishWithProgress(
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
    if (_subscriptionIds != null && _relayPool.isInitialized) {
      _relayPool.unsubscribe(_subscriptionIds!);
    }
    await _eventSubscription?.cancel();
    await _canvasUpdatesController.close();
  }

  void _handleEvent(Event event) {
    if (event.kind != pixelEventKind) return;

    try {
      final pixel = _parsePixelEvent(event);
      if (pixel != null && _canvasData != null) {
        _canvasData = _canvasData!.placePixel(pixel);
        _canvasUpdatesController.add(_canvasData!);
      }
    } on Object {
      // Skip malformed events
    }
  }

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
      pubkey: event.pubkey,
    );
  }
}
