import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_place/canvas/data/models/models.dart';

void main() {
  group('Pixel', () {
    final timestamp = DateTime(2024);
    const position = Position(10, 20);
    const color = Colors.orange;

    test('can be instantiated', () {
      final pixel = Pixel(
        position: position,
        color: color,
        timestamp: timestamp,
      );

      expect(pixel, isNotNull);
      expect(pixel.position, equals(position));
      expect(pixel.color, equals(color));
      expect(pixel.timestamp, equals(timestamp));
    });

    test('supports value equality', () {
      final pixel1 = Pixel(
        position: position,
        color: color,
        timestamp: timestamp,
      );

      final pixel2 = Pixel(
        position: position,
        color: color,
        timestamp: timestamp,
      );

      expect(pixel1, equals(pixel2));
    });

    test('different pixels are not equal', () {
      final pixel1 = Pixel(
        position: position,
        color: color,
        timestamp: timestamp,
      );

      final pixel2 = Pixel(
        position: const Position(11, 20),
        color: color,
        timestamp: timestamp,
      );

      expect(pixel1, isNot(equals(pixel2)));
    });

    test('copyWith creates new pixel with updated values', () {
      final original = Pixel(
        position: position,
        color: color,
        timestamp: timestamp,
      );

      const newPosition = Position(30, 40);
      final updated = original.copyWith(position: newPosition);

      expect(updated.position, equals(newPosition));
      expect(updated.color, equals(color));
      expect(updated.timestamp, equals(timestamp));
      expect(updated, isNot(equals(original)));
    });

    test('copyWith with no arguments returns equal pixel', () {
      final original = Pixel(
        position: position,
        color: color,
        timestamp: timestamp,
      );

      final copy = original.copyWith();

      expect(copy, equals(original));
    });
  });
}
