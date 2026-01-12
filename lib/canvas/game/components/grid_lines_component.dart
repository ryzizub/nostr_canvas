import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nostr_canvas/core/constants.dart';

/// Renders grid lines to show pixel boundaries.
class GridLinesComponent extends PositionComponent {
  GridLinesComponent({
    required int gridWidth,
    required int gridHeight,
  }) : _gridWidth = gridWidth,
       _gridHeight = gridHeight,
       super(
         position: Vector2.zero(),
         size: Vector2(
           gridWidth * Constants.tileSize,
           gridHeight * Constants.tileSize,
         ),
         priority: -1, // Render behind pixels
       );

  final int _gridWidth;
  final int _gridHeight;

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (var x = 0; x <= _gridWidth; x++) {
      final xPos = x * Constants.tileSize;
      canvas.drawLine(
        Offset(xPos, 0),
        Offset(xPos, size.y),
        paint,
      );
    }

    // Draw horizontal lines
    for (var y = 0; y <= _gridHeight; y++) {
      final yPos = y * Constants.tileSize;
      canvas.drawLine(
        Offset(0, yPos),
        Offset(size.x, yPos),
        paint,
      );
    }
  }
}
