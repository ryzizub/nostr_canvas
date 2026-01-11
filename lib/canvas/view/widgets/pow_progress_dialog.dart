import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';

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
              _buildIcon(),
              const SizedBox(height: 16),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              if (progress.phase == PlacementPhase.mining) ...[
                const SizedBox(height: 16),
                _buildStats(),
              ],
              if (progress.phase == PlacementPhase.error) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(),
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

  Widget _buildIcon() {
    return switch (progress.phase) {
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

  Widget _buildTitle() {
    final text = switch (progress.phase) {
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

  Widget _buildSubtitle() {
    final text = switch (progress.phase) {
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

  Widget _buildStats() {
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

  Widget _buildErrorMessage() {
    return NesContainer(
      backgroundColor: Colors.red.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(8),
      child: Text(
        progress.errorMessage ?? 'Unknown error',
        style: TextStyle(
          fontSize: 10,
          color: Colors.red[300],
        ),
        textAlign: TextAlign.center,
      ),
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
