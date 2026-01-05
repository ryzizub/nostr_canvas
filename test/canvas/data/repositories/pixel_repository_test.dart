import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_place/canvas/data/models/models.dart';
import 'package:nostr_place/canvas/data/repositories/pixel_repository.dart';

void main() {
  group('InMemoryPixelRepository', () {
    late PixelRepository repository;

    setUp(() {
      repository = InMemoryPixelRepository();
    });

    test('loadCanvas returns canvas with correct dimensions', () async {
      final canvas = await repository.loadCanvas();

      expect(canvas.width, equals(1000));
      expect(canvas.height, equals(1000));
      expect(canvas.pixels, isEmpty);
    });

    test('loadCanvas can use custom dimensions', () async {
      final customRepository = InMemoryPixelRepository(
        canvasWidth: 500,
        canvasHeight: 500,
      );

      final canvas = await customRepository.loadCanvas();

      expect(canvas.width, equals(500));
      expect(canvas.height, equals(500));
    });

    test('placePixel stores pixel successfully', () async {
      final pixel = Pixel(
        position: const Position(10, 20),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      await repository.placePixel(pixel);

      final canvas = await repository.loadCanvas();
      expect(canvas.pixels, hasLength(1));
      expect(canvas.getPixel(const Position(10, 20)), equals(pixel));
    });

    test('placePixel throws exception for out of bounds position', () async {
      final pixel = Pixel(
        position: const Position(1000, 1000), // Out of bounds (0-999)
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      expect(
        () => repository.placePixel(pixel),
        throwsException,
      );
    });

    test('placePixel throws exception for negative x', () async {
      final pixel = Pixel(
        position: const Position(-1, 10),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      expect(
        () => repository.placePixel(pixel),
        throwsException,
      );
    });

    test('placePixel throws exception for negative y', () async {
      final pixel = Pixel(
        position: const Position(10, -1),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      expect(
        () => repository.placePixel(pixel),
        throwsException,
      );
    });

    test('placePixel throws exception for x >= width', () async {
      final pixel = Pixel(
        position: const Position(1000, 500),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      expect(
        () => repository.placePixel(pixel),
        throwsException,
      );
    });

    test('placePixel throws exception for y >= height', () async {
      final pixel = Pixel(
        position: const Position(500, 1000),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      expect(
        () => repository.placePixel(pixel),
        throwsException,
      );
    });

    test('placePixel accepts pixels at max valid coordinates', () async {
      final pixel = Pixel(
        position: const Position(999, 999),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      await repository.placePixel(pixel);

      final canvas = await repository.loadCanvas();
      expect(canvas.getPixel(const Position(999, 999)), equals(pixel));
    });

    test('multiple pixels can be placed', () async {
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

      await repository.placePixel(pixel1);
      await repository.placePixel(pixel2);

      final canvas = await repository.loadCanvas();
      expect(canvas.pixels, hasLength(2));
    });

    test('placePixel overwrites existing pixel at same position', () async {
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

      await repository.placePixel(pixel1);
      await repository.placePixel(pixel2);

      final canvas = await repository.loadCanvas();
      expect(canvas.pixels, hasLength(1));
      expect(
        canvas.getPixel(const Position(10, 20))?.color,
        equals(Colors.blue),
      );
    });

    test('clearCanvas removes all pixels', () async {
      final pixel = Pixel(
        position: const Position(10, 20),
        color: Colors.orange,
        timestamp: DateTime.now(),
      );

      await repository.placePixel(pixel);
      await repository.clearCanvas();

      final canvas = await repository.loadCanvas();
      expect(canvas.pixels, isEmpty);
    });

    test('clearCanvas preserves canvas dimensions', () async {
      await repository.clearCanvas();

      final canvas = await repository.loadCanvas();
      expect(canvas.width, equals(1000));
      expect(canvas.height, equals(1000));
    });
  });
}
