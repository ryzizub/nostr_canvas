import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/data/models/position.dart';

/// Represents a pixel on the canvas.
class Pixel extends Equatable {
  const Pixel({
    required this.position,
    required this.color,
    required this.timestamp,
  });

  final Position position;
  final Color color;
  final DateTime timestamp;

  @override
  List<Object?> get props => [position, color, timestamp];

  Pixel copyWith({
    Position? position,
    Color? color,
    DateTime? timestamp,
  }) {
    return Pixel(
      position: position ?? this.position,
      color: color ?? this.color,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
