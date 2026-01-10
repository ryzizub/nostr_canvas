import 'package:equatable/equatable.dart';

/// Represents a coordinate on the canvas grid.
class Position extends Equatable {
  const Position(this.x, this.y);

  final int x;
  final int y;

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'Position($x, $y)';
}
