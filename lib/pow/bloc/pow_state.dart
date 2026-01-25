part of 'pow_bloc.dart';

enum PowStatus { idle, mining, sending, error }

/// Phase of the placement operation (for UI display).
enum PlacementPhase { mining, sending, success, error }

/// Maximum number of pixels that can be queued.
const int maxQueueSize = 10;

/// Progress of a pixel placement operation.
class PlacementProgress extends Equatable {
  const PlacementProgress({
    required this.phase,
    this.noncesAttempted = 0,
    this.currentDifficulty = 0,
    this.targetDifficulty = 0,
    this.hashRate = 0.0,
    this.errorMessage,
  });

  final PlacementPhase phase;
  final int noncesAttempted;
  final int currentDifficulty;
  final int targetDifficulty;
  final double hashRate;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    phase,
    noncesAttempted,
    currentDifficulty,
    targetDifficulty,
    hashRate,
    errorMessage,
  ];
}

class PowState extends Equatable {
  const PowState({
    this.status = PowStatus.idle,
    this.progress,
    this.queue = const [],
    this.currentPixel,
  });

  final PowStatus status;
  final PlacementProgress? progress;

  /// Ordered list of queued pixels waiting to be processed.
  final List<QueuedPixel> queue;

  /// The pixel currently being processed (mining/sending).
  final QueuedPixel? currentPixel;

  /// Whether there are pixels in the queue.
  bool get hasQueuedPixels => queue.isNotEmpty;

  /// Number of pixels in the queue.
  int get queueLength => queue.length;

  /// Whether more pixels can be added to the queue.
  bool get canAddToQueue => queue.length < maxQueueSize;

  @override
  List<Object?> get props => [status, progress, queue, currentPixel];

  PowState copyWith({
    PowStatus? status,
    PlacementProgress? Function()? progress,
    List<QueuedPixel>? queue,
    QueuedPixel? Function()? currentPixel,
  }) {
    return PowState(
      status: status ?? this.status,
      progress: progress != null ? progress() : this.progress,
      queue: queue ?? this.queue,
      currentPixel: currentPixel != null ? currentPixel() : this.currentPixel,
    );
  }
}
