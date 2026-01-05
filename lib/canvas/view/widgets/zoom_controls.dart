import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/game/canvas_game_bridge.dart';

class ZoomControls extends StatefulWidget {
  const ZoomControls({
    required this.bridge,
    super.key,
  });

  final CanvasGameBridge bridge;

  @override
  State<ZoomControls> createState() => _ZoomControlsState();
}

class _ZoomControlsState extends State<ZoomControls> {
  void _zoomIn() {
    final currentZoom = widget.bridge.game.zoom;
    final newZoom = (currentZoom * 1.2).clamp(0.1, 50.0);
    widget.bridge.updateZoom(newZoom);
  }

  void _zoomOut() {
    final currentZoom = widget.bridge.game.zoom;
    final newZoom = (currentZoom / 1.2).clamp(0.1, 50.0);
    widget.bridge.updateZoom(newZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'zoom_in',
          onPressed: _zoomIn,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'zoom_out',
          onPressed: _zoomOut,
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }
}
