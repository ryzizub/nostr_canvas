import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/pow/bloc/pow_bloc.dart';
import 'package:nostr_canvas/pow/models/queued_pixel.dart';

/// Bottom sheet panel showing the pixel queue.
class PixelQueuePanel extends StatelessWidget {
  const PixelQueuePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PowBloc, PowState>(
      builder: (context, state) {
        final items = <_QueueItem>[];

        // Add current pixel if processing
        if (state.currentPixel != null) {
          items.add(
            _QueueItem(
              pixel: state.currentPixel!,
              position: 0,
              isProcessing: true,
            ),
          );
        }

        // Add queued pixels
        for (var i = 0; i < state.queue.length; i++) {
          items.add(
            _QueueItem(
              pixel: state.queue[i],
              position: i + 1,
            ),
          );
        }

        return NesContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pixel Queue',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (items.isNotEmpty)
                    NesButton(
                      type: NesButtonType.error,
                      onPressed: () {
                        context.read<PowBloc>().add(const PowQueueCleared());
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear All'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _EmptyQueueMessage()
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _QueueItemTile(
                        pixel: item.pixel,
                        position: item.position,
                        isProcessing: item.isProcessing,
                        onRemove: item.isProcessing
                            ? null
                            : () {
                                context.read<PowBloc>().add(
                                  PowQueueItemRemoved(pixelId: item.pixel.id),
                                );
                              },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueItem {
  const _QueueItem({
    required this.pixel,
    required this.position,
    this.isProcessing = false,
  });

  final QueuedPixel pixel;
  final int position;
  final bool isProcessing;
}

class _EmptyQueueMessage extends StatelessWidget {
  const _EmptyQueueMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(
        'No pixels queued',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

class _QueueItemTile extends StatelessWidget {
  const _QueueItemTile({
    required this.pixel,
    required this.position,
    required this.isProcessing,
    this.onRemove,
  });

  final QueuedPixel pixel;
  final int position;
  final bool isProcessing;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      padding: const EdgeInsets.all(8),
      backgroundColor: isProcessing ? Colors.blue.withValues(alpha: 0.1) : null,
      child: Row(
        children: [
          // Position badge
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isProcessing ? Colors.blue : Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isProcessing ? '⚡' : position.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Color swatch
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: pixel.color,
              border: Border.all(),
            ),
          ),
          const SizedBox(width: 8),
          // Position text
          Expanded(
            child: Text(
              '(${pixel.position.x}, ${pixel.position.y})',
              style: const TextStyle(fontSize: 11),
            ),
          ),
          // Status or remove button
          if (isProcessing)
            const NesHourglassLoadingIndicator()
          else if (onRemove != null)
            NesIconButton(
              icon: NesIcons.close,
              size: const Size.square(16),
              onPress: onRemove,
            ),
        ],
      ),
    );
  }
}
