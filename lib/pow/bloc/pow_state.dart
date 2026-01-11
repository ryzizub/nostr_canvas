part of 'pow_bloc.dart';

enum PowStatus { idle, mining, sending, error }

/// Phase of the placement operation (for UI display).
enum PlacementPhase { mining, sending, success, error }

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
  });

  final PowStatus status;
  final PlacementProgress? progress;

  @override
  List<Object?> get props => [status, progress];

  PowState copyWith({
    PowStatus? status,
    PlacementProgress? Function()? progress,
  }) {
    return PowState(
      status: status ?? this.status,
      progress: progress != null ? progress() : this.progress,
    );
  }
}
