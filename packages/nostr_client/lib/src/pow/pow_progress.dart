import 'package:equatable/equatable.dart';

/// Proof of Work mining progress.
sealed class PowProgress extends Equatable {
  const PowProgress();

  @override
  List<Object?> get props => [];
}

/// Mining is in progress.
class PowMining extends PowProgress {
  const PowMining({
    required this.noncesAttempted,
    required this.currentDifficulty,
    required this.targetDifficulty,
    required this.elapsedMilliseconds,
  });

  /// Number of nonces attempted so far.
  final int noncesAttempted;

  /// Best difficulty achieved so far.
  final int currentDifficulty;

  /// Target difficulty to achieve.
  final int targetDifficulty;

  /// Time elapsed since mining started in milliseconds.
  final int elapsedMilliseconds;

  /// Estimated hash rate (nonces per second).
  double get hashRate => elapsedMilliseconds > 0
      ? noncesAttempted / elapsedMilliseconds * 1000
      : 0;

  @override
  List<Object?> get props => [
    noncesAttempted,
    currentDifficulty,
    targetDifficulty,
    elapsedMilliseconds,
  ];
}

/// Mining completed successfully.
class PowComplete extends PowProgress {
  const PowComplete({
    required this.nonce,
    required this.achievedDifficulty,
    required this.targetDifficulty,
    required this.elapsedMilliseconds,
    required this.createdAt,
  });

  /// The winning nonce value.
  final String nonce;

  final int achievedDifficulty;
  final int targetDifficulty;
  final int elapsedMilliseconds;

  /// The timestamp used during mining (must be used when creating the event).
  final int createdAt;

  @override
  List<Object?> get props => [
    nonce,
    achievedDifficulty,
    targetDifficulty,
    elapsedMilliseconds,
    createdAt,
  ];
}

/// Sending the event to relay.
class PowSending extends PowProgress {
  const PowSending();
}

/// Event successfully published.
class PowSuccess extends PowProgress {
  const PowSuccess({required this.eventId});

  final String eventId;

  @override
  List<Object?> get props => [eventId];
}

/// An error occurred.
class PowError extends PowProgress {
  const PowError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
