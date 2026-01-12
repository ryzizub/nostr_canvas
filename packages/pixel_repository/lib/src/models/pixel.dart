import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pixel_repository/src/models/position.dart';

/// Represents a pixel on the canvas.
class Pixel extends Equatable {
  const Pixel({
    required this.position,
    required this.color,
    required this.timestamp,
    required this.pubkey,
  });

  final Position position;
  final Color color;
  final DateTime timestamp;
  final String pubkey;

  @override
  List<Object?> get props => [position, color, timestamp, pubkey];

  Pixel copyWith({
    Position? position,
    Color? color,
    DateTime? timestamp,
    String? pubkey,
  }) {
    return Pixel(
      position: position ?? this.position,
      color: color ?? this.color,
      timestamp: timestamp ?? this.timestamp,
      pubkey: pubkey ?? this.pubkey,
    );
  }
}
