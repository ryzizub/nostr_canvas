import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Represents a pixel queued for placement.
class QueuedPixel extends Equatable {
  QueuedPixel({
    required this.position,
    required this.color,
    DateTime? addedAt,
  }) : id =
           '${position.x}_${position.y}_'
           '${DateTime.now().microsecondsSinceEpoch}',
       addedAt = addedAt ?? DateTime.now();

  final String id;
  final Position position;
  final Color color;
  final DateTime addedAt;

  @override
  List<Object?> get props => [id, position, color, addedAt];
}
