part of 'pow_bloc.dart';

abstract class PowEvent extends Equatable {
  const PowEvent();

  @override
  List<Object?> get props => [];
}

/// Request to place a pixel with PoW mining.
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

/// Dismiss the PoW dialog (after error).
class PowDismissed extends PowEvent {
  const PowDismissed();
}
