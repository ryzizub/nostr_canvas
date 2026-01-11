import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nostr_client/nostr_client.dart';
import 'package:pixel_repository/pixel_repository.dart';

part 'pow_event.dart';
part 'pow_state.dart';

class PowBloc extends Bloc<PowEvent, PowState> {
  PowBloc({
    required PixelRepository pixelRepository,
  }) : _pixelRepository = pixelRepository,
       super(const PowState()) {
    on<PowPlacePixelRequested>(_onPlacePixelRequested);
    on<PowDismissed>(_onDismissed);
  }

  final PixelRepository _pixelRepository;

  Future<void> _onPlacePixelRequested(
    PowPlacePixelRequested event,
    Emitter<PowState> emit,
  ) async {
    if (state.status != PowStatus.idle) return;

    emit(
      state.copyWith(
        status: PowStatus.mining,
        progress: () => const PlacementProgress(phase: PlacementPhase.mining),
      ),
    );

    try {
      await emit.forEach<PowProgress>(
        _pixelRepository.placePixelWithProgress(event.position, event.color),
        onData: (progress) {
          return switch (progress) {
            PowMining(
              :final noncesAttempted,
              :final currentDifficulty,
              :final targetDifficulty,
              :final hashRate,
            ) =>
              state.copyWith(
                status: PowStatus.mining,
                progress: () => PlacementProgress(
                  phase: PlacementPhase.mining,
                  noncesAttempted: noncesAttempted,
                  currentDifficulty: currentDifficulty,
                  targetDifficulty: targetDifficulty,
                  hashRate: hashRate,
                ),
              ),
            PowComplete() => state.copyWith(
              status: PowStatus.sending,
              progress: () =>
                  const PlacementProgress(phase: PlacementPhase.sending),
            ),
            PowSending() => state.copyWith(
              status: PowStatus.sending,
              progress: () =>
                  const PlacementProgress(phase: PlacementPhase.sending),
            ),
            PowSuccess() => state.copyWith(
              status: PowStatus.idle,
              progress: () => null,
            ),
            PowError(:final message) => state.copyWith(
              status: PowStatus.error,
              progress: () => PlacementProgress(
                phase: PlacementPhase.error,
                errorMessage: message,
              ),
            ),
          };
        },
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: PowStatus.error,
          progress: () => PlacementProgress(
            phase: PlacementPhase.error,
            errorMessage: error.toString(),
          ),
        ),
      );
    }
  }

  void _onDismissed(
    PowDismissed event,
    Emitter<PowState> emit,
  ) {
    emit(
      state.copyWith(
        status: PowStatus.idle,
        progress: () => null,
      ),
    );
  }
}
