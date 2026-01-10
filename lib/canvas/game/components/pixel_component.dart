import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/canvas_constants.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Renders a single pixel on the canvas.
class PixelComponent extends RectangleComponent {
  PixelComponent({
    required Position position,
    required Color color,
  }) : super(
         position: Vector2(
           position.x.toDouble() * CanvasConstants.tileSize,
           position.y.toDouble() * CanvasConstants.tileSize,
         ),
         size: Vector2.all(CanvasConstants.tileSize),
         paint: Paint()
           ..color = color
           ..isAntiAlias = false
           ..style = PaintingStyle.fill,
       );

  Color get color => paint.color;

  set color(Color value) {
    paint.color = value;
  }
}
