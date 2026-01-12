import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/pow/bloc/pow_bloc.dart';

/// Dialog showing PoW mining and sending progress with NES styling.
class PowProgressDialog extends StatelessWidget {
  const PowProgressDialog({
    required this.progress,
    this.onDismiss,
    super.key,
  });

  final PlacementProgress progress;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: NesContainer(
          width: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PhaseIcon(phase: progress.phase),
              const SizedBox(height: 16),
              _PhaseTitle(phase: progress.phase),
              const SizedBox(height: 8),
              _PhaseSubtitle(phase: progress.phase),
              if (progress.phase == PlacementPhase.mining) ...[
                const SizedBox(height: 16),
                _MiningStats(progress: progress),
              ],
              if (progress.phase == PlacementPhase.error) ...[
                const SizedBox(height: 16),
                _ErrorMessage(message: progress.errorMessage),
                const SizedBox(height: 16),
                NesButton(
                  type: NesButtonType.error,
                  onPressed: onDismiss,
                  child: const Text('Close'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon({required this.phase});

  final PlacementPhase phase;

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      PlacementPhase.mining => const NesHourglassLoadingIndicator(),
      PlacementPhase.sending => const NesHourglassLoadingIndicator(),
      PlacementPhase.success => NesIcon(
        iconData: NesIcons.check,
        size: const Size.square(48),
        primaryColor: Colors.green,
      ),
      PlacementPhase.error => NesIcon(
        iconData: NesIcons.close,
        size: const Size.square(48),
        primaryColor: Colors.red,
      ),
    };
  }
}

class _PhaseTitle extends StatelessWidget {
  const _PhaseTitle({required this.phase});

  final PlacementPhase phase;

  @override
  Widget build(BuildContext context) {
    final text = switch (phase) {
      PlacementPhase.mining => 'Mining PoW',
      PlacementPhase.sending => 'Sending',
      PlacementPhase.success => 'Success!',
      PlacementPhase.error => 'Error',
    };

    return Text(
      text,
      style: const TextStyle(fontSize: 16),
    );
  }
}

class _PhaseSubtitle extends StatelessWidget {
  const _PhaseSubtitle({required this.phase});

  final PlacementPhase phase;

  @override
  Widget build(BuildContext context) {
    final text = switch (phase) {
      PlacementPhase.mining => 'Finding valid nonce...',
      PlacementPhase.sending => 'Publishing to relay...',
      PlacementPhase.success => 'Pixel placed!',
      PlacementPhase.error => 'Failed to place pixel',
    };

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[400],
      ),
    );
  }
}

class _MiningStats extends StatelessWidget {
  const _MiningStats({required this.progress});

  final PlacementProgress progress;

  @override
  Widget build(BuildContext context) {
    final difficultyProgress =
        '${progress.currentDifficulty}/${progress.targetDifficulty} bits';
    final hashRate = _formatHashRate(progress.hashRate);
    final nonces = _formatNumber(progress.noncesAttempted);

    return Column(
      children: [
        _StatRow(label: 'Difficulty', value: difficultyProgress),
        const SizedBox(height: 4),
        _StatRow(label: 'Nonces', value: nonces),
        const SizedBox(height: 4),
        _StatRow(label: 'Hash rate', value: hashRate),
      ],
    );
  }

  String _formatHashRate(double rate) {
    if (rate >= 1000000) {
      return '${(rate / 1000000).toStringAsFixed(1)} MH/s';
    } else if (rate >= 1000) {
      return '${(rate / 1000).toStringAsFixed(1)} KH/s';
    } else {
      return '${rate.toStringAsFixed(0)} H/s';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      backgroundColor: Colors.red.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(8),
      child: Text(
        message ?? 'Unknown error',
        style: TextStyle(
          fontSize: 10,
          color: Colors.red[300],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
