import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_place/canvas/data/models/position.dart';

void main() {
  group('Position', () {
    test('can be instantiated', () {
      expect(const Position(0, 0), isNotNull);
    });

    test('supports value equality', () {
      expect(
        const Position(10, 20),
        equals(const Position(10, 20)),
      );
    });

    test('different positions are not equal', () {
      expect(
        const Position(10, 20),
        isNot(equals(const Position(10, 21))),
      );
      expect(
        const Position(10, 20),
        isNot(equals(const Position(11, 20))),
      );
    });

    test('toString returns correct format', () {
      expect(
        const Position(5, 7).toString(),
        equals('Position(5, 7)'),
      );
    });

    test('handles negative coordinates', () {
      expect(const Position(-1, -1), isNotNull);
      expect(const Position(-1, -1).x, equals(-1));
      expect(const Position(-1, -1).y, equals(-1));
    });

    test('handles large coordinates', () {
      const position = Position(999, 999);
      expect(position.x, equals(999));
      expect(position.y, equals(999));
    });
  });
}
