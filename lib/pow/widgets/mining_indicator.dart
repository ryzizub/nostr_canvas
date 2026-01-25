import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/pow/bloc/pow_bloc.dart';

/// Non-blocking mining indicator shown in top-right corner.
/// Displays mining progress, queue count, and error actions.
class MiningIndicator extends StatelessWidget {
  const MiningIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PowBloc, PowState>(
      builder: (context, state) {
        if (state.status == PowStatus.idle) {
          return const SizedBox.shrink();
        }

        final progress = state.progress;
        if (progress == null) {
          return const SizedBox.shrink();
        }

        return _MiningIndicatorContent(
          progress: progress,
          queueLength: state.queueLength,
        );
      },
    );
  }
}

class _MiningIndicatorContent extends StatelessWidget {
  const _MiningIndicatorContent({
    required this.progress,
    required this.queueLength,
  });

  final PlacementProgress progress;
  final int queueLength;

  @override
  Widget build(BuildContext context) {
    final isError = progress.phase == PlacementPhase.error;

    return NesContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusRow(progress: progress),
          if (!isError && queueLength > 0) ...[
            const SizedBox(height: 8),
            _QueueCount(count: queueLength),
          ],
          if (isError) ...[
            const SizedBox(height: 8),
            _ErrorSection(
              message: progress.errorMessage,
              queueLength: queueLength,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.progress});

  final PlacementProgress progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PhaseIndicator(phase: progress.phase),
        const SizedBox(width: 8),
        _PhaseText(progress: progress),
      ],
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({required this.phase});

  final PlacementPhase phase;

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      PlacementPhase.mining => const SizedBox(
        width: 16,
        height: 16,
        child: FittedBox(
          child: NesHourglassLoadingIndicator(),
        ),
      ),
      PlacementPhase.sending => const SizedBox(
        width: 16,
        height: 16,
        child: FittedBox(
          child: NesHourglassLoadingIndicator(),
        ),
      ),
      PlacementPhase.success => NesIcon(
        iconData: NesIcons.check,
        size: const Size.square(16),
        primaryColor: Colors.green,
      ),
      PlacementPhase.error => NesIcon(
        iconData: NesIcons.close,
        size: const Size.square(16),
        primaryColor: Colors.red,
      ),
    };
  }
}

class _PhaseText extends StatelessWidget {
  const _PhaseText({required this.progress});

  final PlacementProgress progress;

  @override
  Widget build(BuildContext context) {
    final text = switch (progress.phase) {
      PlacementPhase.mining => 'Mining...',
      PlacementPhase.sending => 'Sending...',
      PlacementPhase.success => 'Done!',
      PlacementPhase.error => 'Error',
    };

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: progress.phase == PlacementPhase.error ? Colors.red : null,
      ),
    );
  }
}

class _QueueCount extends StatelessWidget {
  const _QueueCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count in queue',
      style: TextStyle(
        fontSize: 10,
        color: Colors.blue[300],
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({
    required this.message,
    required this.queueLength,
  });

  final String? message;
  final int queueLength;

  @override
  Widget build(BuildContext context) {
    final powBloc = context.read<PowBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message != null) ...[
          Text(
            message!,
            style: TextStyle(
              fontSize: 9,
              color: Colors.red[300],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            NesButton(
              type: NesButtonType.primary,
              onPressed: () => powBloc.add(const PowQueueRetried()),
              child: const Text('Retry', style: TextStyle(fontSize: 10)),
            ),
            if (queueLength > 0)
              NesButton(
                type: NesButtonType.warning,
                onPressed: () => powBloc.add(const PowQueueSkipped()),
                child: const Text('Skip', style: TextStyle(fontSize: 10)),
              ),
            if (queueLength > 0)
              NesButton(
                type: NesButtonType.error,
                onPressed: () => powBloc.add(const PowQueueCleared()),
                child: const Text('Clear', style: TextStyle(fontSize: 10)),
              ),
            NesButton(
              type: NesButtonType.normal,
              onPressed: () => powBloc.add(const PowDismissed()),
              child: const Text('Dismiss', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ],
    );
  }
}
