import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';

/// Dialog showing PoW mining and sending progress.
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
    return AlertDialog(
      content: Column(
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
          ],
        ],
      ),
      actions: progress.phase == PlacementPhase.error
          ? [
              TextButton(
                onPressed: onDismiss,
                child: const Text('Close'),
              ),
            ]
          : null,
    );
  }

  Widget _buildIcon() {
    return switch (progress.phase) {
      PlacementPhase.mining => const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
      PlacementPhase.sending => const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
      PlacementPhase.success => const Icon(
        Icons.check_circle,
        size: 48,
        color: Colors.green,
      ),
      PlacementPhase.error => const Icon(
        Icons.error,
        size: 48,
        color: Colors.red,
      ),
    };
  }

  Widget _buildTitle() {
    final text = switch (progress.phase) {
      PlacementPhase.mining => 'Mining PoW',
      PlacementPhase.sending => 'Sending',
      PlacementPhase.success => 'Success',
      PlacementPhase.error => 'Error',
    };

    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
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
        fontSize: 14,
        color: Colors.grey[600],
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
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        progress.errorMessage ?? 'Unknown error',
        style: TextStyle(
          fontSize: 12,
          color: Colors.red[700],
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
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
