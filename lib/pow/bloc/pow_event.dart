part of 'pow_bloc.dart';

abstract class PowEvent extends Equatable {
  const PowEvent();

  @override
  List<Object?> get props => [];
}

/// Request to place a pixel with PoW mining (legacy - direct placement).
class PowPlacePixelRequested extends PowEvent {
  const PowPlacePixelRequested({
    required this.position,
    required this.color,
  });

  final Position position;
  final Color color;

  @override
  List<Object?> get props => [position, color];
}

/// Add a pixel to the queue for processing.
class PowPixelQueued extends PowEvent {
  const PowPixelQueued({
    required this.position,
    required this.color,
  });

  final Position position;
  final Color color;

  @override
  List<Object?> get props => [position, color];
}

/// Remove a specific pixel from the queue by ID.
class PowQueueItemRemoved extends PowEvent {
  const PowQueueItemRemoved({required this.pixelId});

  final String pixelId;

  @override
  List<Object?> get props => [pixelId];
}

/// Clear the entire queue.
class PowQueueCleared extends PowEvent {
  const PowQueueCleared();
}

/// Resume processing after an error (retry current pixel).
class PowQueueRetried extends PowEvent {
  const PowQueueRetried();
}

/// Skip the current errored pixel and process next.
class PowQueueSkipped extends PowEvent {
  const PowQueueSkipped();
}

/// Internal event: process the next pixel in queue.
class _PowProcessNextQueued extends PowEvent {
  const _PowProcessNextQueued();
}

/// Dismiss the PoW dialog (after error).
class PowDismissed extends PowEvent {
  const PowDismissed();
}
