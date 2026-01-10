import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/canvas_constants.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Displays a highlight border around a recently clicked pixel.
class ClickHighlightComponent extends PositionComponent {
  ClickHighlightComponent({
    required Position gridPosition,
  }) : super(
         position: Vector2(
           gridPosition.x * CanvasConstants.tileSize,
           gridPosition.y * CanvasConstants.tileSize,
         ),
         size: Vector2.all(CanvasConstants.tileSize),
       );

  static const _borderWidth = 1.0;
  static const _highlightDuration = Duration(milliseconds: 500);

  @override
  Future<void> onLoad() async {
    // Add a rectangle component with a border
    await add(
      RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill,
        children: [
          RectangleComponent(
            size: size,
            paint: Paint()
              ..color = Colors.black
              ..style = PaintingStyle.stroke
              ..strokeWidth = _borderWidth,
          ),
        ],
      ),
    );

    // Remove this highlight after the duration
    Future<void>.delayed(_highlightDuration, removeFromParent);
  }
}
