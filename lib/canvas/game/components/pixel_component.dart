import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/core/constants.dart';

/// Renders a single pixel on the canvas.
class PixelComponent extends RectangleComponent {
  PixelComponent({
    required int x,
    required int y,
    required Color color,
  }) : super(
         position: Vector2(
           x.toDouble() * Constants.tileSize,
           y.toDouble() * Constants.tileSize,
         ),
         size: Vector2.all(Constants.tileSize),
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
