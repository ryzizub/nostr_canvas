import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_place/canvas/data/models/models.dart';

void main() {
  group('CanvasData', () {
    const canvasWidth = 1000;
    const canvasHeight = 1000;

    test('can be instantiated with empty pixels', () {
      const canvasData = CanvasData(
        width: canvasWidth,
        height: canvasHeight,
      );

      expect(canvasData, isNotNull);
      expect(canvasData.width, equals(canvasWidth));
      expect(canvasData.height, equals(canvasHeight));
      expect(canvasData.pixels, isEmpty);
    });

    test('getPixel returns null for empty position', () {
      const canvasData = CanvasData(
        width: canvasWidth,
        height: canvasHeight,
      );

      expect(canvasData.getPixel(const Position(0, 0)), isNull);
      expect(canvasData.getPixel(const Position(500, 500)), isNull);
    });

    test('placePixel adds pixel to canvas', () {
      const canvasData = CanvasData(
        width: canvasWidth,
        height: canvasHeight,
      );

      final pixel = Pixel(
        position: const Position(10, 20),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      final updated = canvasData.placePixel(pixel);

      expect(updated.pixels, hasLength(1));
      expect(
        updated.getPixel(const Position(10, 20)),
        equals(pixel),
      );
    });

    test('placePixel does not mutate original canvas', () {
      const canvasData = CanvasData(
        width: canvasWidth,
        height: canvasHeight,
      );

      final pixel = Pixel(
        position: const Position(10, 20),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      canvasData.placePixel(pixel);

      expect(canvasData.pixels, isEmpty);
    });

    test('placePixel overwrites existing pixel at position', () {
      const canvasData = CanvasData(
        width: canvasWidth,
        height: canvasHeight,
      );

      final pixel1 = Pixel(
        position: const Position(10, 20),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      final pixel2 = Pixel(
        position: const Position(10, 20),
        color: Colors.blue,
        timestamp: DateTime.now(),
      );

      final updated1 = canvasData.placePixel(pixel1);
      final updated2 = updated1.placePixel(pixel2);

      expect(updated2.pixels, hasLength(1));
      expect(
        updated2.getPixel(const Position(10, 20))?.color,
        equals(Colors.blue),
      );
    });

    test('multiple pixels can be placed', () {
      const canvasData = CanvasData(
        width: canvasWidth,
        height: canvasHeight,
      );

      final pixel1 = Pixel(
        position: const Position(10, 20),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      final pixel2 = Pixel(
        position: const Position(30, 40),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      final pixel3 = Pixel(
        position: const Position(50, 60),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      final updated = canvasData
          .placePixel(pixel1)
          .placePixel(pixel2)
          .placePixel(pixel3);

      expect(updated.pixels, hasLength(3));
      expect(updated.getPixel(const Position(10, 20)), equals(pixel1));
      expect(updated.getPixel(const Position(30, 40)), equals(pixel2));
      expect(updated.getPixel(const Position(50, 60)), equals(pixel3));
    });

    test('supports value equality', () {
      const canvas1 = CanvasData(
        width: canvasWidth,
        height: canvasHeight,
      );

      const canvas2 = CanvasData(
        width: canvasWidth,
        height: canvasHeight,
      );

      expect(canvas1, equals(canvas2));
    });

    test('different dimensions are not equal', () {
      const canvas1 = CanvasData(width: 100, height: 100);
      const canvas2 = CanvasData(width: 200, height: 200);

      expect(canvas1, isNot(equals(canvas2)));
    });
  });
}
