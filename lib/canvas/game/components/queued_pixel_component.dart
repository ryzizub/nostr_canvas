import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nostr_canvas/core/constants.dart';
import 'package:nostr_canvas/pow/models/queued_pixel.dart';

/// Renders a queued pixel with visual distinction from placed pixels.
class QueuedPixelComponent extends PositionComponent {
  QueuedPixelComponent({
    required this.queuedPixel,
    required this.queuePosition,
    this.isProcessing = false,
  }) : super(
         position: Vector2(
           queuedPixel.position.x * Constants.tileSize,
           queuedPixel.position.y * Constants.tileSize,
         ),
         size: Vector2.all(Constants.tileSize),
       );

  final QueuedPixel queuedPixel;
  final int queuePosition;
  final bool isProcessing;

  static const _borderWidth = 1.0;
  static const _dashLength = 2.0;
  static const _gapLength = 2.0;
  static const _blinkInterval = 0.3;

  late final Paint _fillPaint;
  late final Paint _blinkPaint;
  late final Paint _borderPaint;

  double _blinkTimer = 0;
  bool _showBlink = false;

  @override
  Future<void> onLoad() async {
    // Full color fill for both processing and queued pixels
    _fillPaint = Paint()
      ..color = queuedPixel.color
      ..style = PaintingStyle.fill;

    // White paint for blinking effect on processing pixel
    _blinkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Dashed border paint
    _borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isProcessing) {
      _blinkTimer += dt;
      if (_blinkTimer >= _blinkInterval) {
        _blinkTimer = 0;
        _showBlink = !_showBlink;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw fill - processing pixel blinks between its color and white
    if (isProcessing && _showBlink) {
      canvas.drawRect(size.toRect(), _blinkPaint);
    } else {
      canvas.drawRect(size.toRect(), _fillPaint);
    }

    // Draw dashed border
    _drawDashedBorder(canvas);

    // Always draw queue position badge (including processing pixel)
    _drawQueueBadge(canvas);
  }

  void _drawDashedBorder(Canvas canvas) {
    final rect = size.toRect();
    final path = Path()..addRect(rect);

    // Calculate dash pattern
    final totalLength = (rect.width + rect.height) * 2;
    final dashCount = (totalLength / (_dashLength + _gapLength)).floor();
    final adjustedDashLength = totalLength / dashCount / 2;

    // Draw dashed path
    var distance = 0.0;
    final pathMetric = path.computeMetrics().first;
    while (distance < pathMetric.length) {
      final start = distance;
      final end = math.min(distance + adjustedDashLength, pathMetric.length);
      final dashPath = pathMetric.extractPath(start, end);
      canvas.drawPath(dashPath, _borderPaint);
      distance += adjustedDashLength * 2;
    }
  }

  void _drawQueueBadge(Canvas canvas) {
    // Small badge in top-right corner
    const badgeSize = 6.0;
    const badgeOffset = 1.0;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.x - badgeSize - badgeOffset,
        badgeOffset,
        badgeSize,
        badgeSize,
      ),
      const Radius.circular(1),
    );

    // Badge background and border
    canvas
      ..drawRRect(
        badgeRect,
        Paint()..color = Colors.white,
      )
      ..drawRRect(
        badgeRect,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );

    // Badge text
    final textPainter = TextPainter(
      text: TextSpan(
        text: queuePosition.toString(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        size.x - badgeSize - badgeOffset + (badgeSize - textPainter.width) / 2,
        badgeOffset + (badgeSize - textPainter.height) / 2,
      ),
    );
  }
}
