import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
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

  late final Paint _fillPaint;
  late final Paint _borderPaint;

  @override
  Future<void> onLoad() async {
    // Semi-transparent fill
    _fillPaint = Paint()
      ..color = queuedPixel.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Dashed border paint
    _borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;

    // Add pulsing effect for currently processing pixel
    if (isProcessing) {
      await add(
        OpacityEffect.to(
          0.5,
          EffectController(
            duration: 0.5,
            reverseDuration: 0.5,
            infinite: true,
          ),
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw semi-transparent fill
    canvas.drawRect(size.toRect(), _fillPaint);

    // Draw dashed border
    _drawDashedBorder(canvas);

    // Draw queue position badge
    if (!isProcessing && queuePosition > 0) {
      _drawQueueBadge(canvas);
    }
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
    const badgeSize = 8.0;
    const badgeOffset = 2.0;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.x - badgeSize - badgeOffset,
        badgeOffset,
        badgeSize,
        badgeSize,
      ),
      const Radius.circular(2),
    );

    // Badge background
    canvas.drawRRect(
      badgeRect,
      Paint()..color = Colors.black87,
    );

    // Badge text
    final textPainter = TextPainter(
      text: TextSpan(
        text: queuePosition.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 6,
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
