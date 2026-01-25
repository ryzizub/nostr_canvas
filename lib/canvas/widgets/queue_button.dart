import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/pow/pow.dart';

/// Toolbar button that shows queue count and opens queue panel.
class QueueButton extends StatelessWidget {
  const QueueButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PowBloc, PowState>(
      buildWhen: (previous, current) =>
          previous.queueLength != current.queueLength ||
          previous.currentPixel != current.currentPixel,
      builder: (context, state) {
        final totalCount =
            state.queueLength + (state.currentPixel != null ? 1 : 0);

        return Tooltip(
          message: totalCount > 0 ? 'Queue ($totalCount)' : 'Queue',
          preferBelow: false,
          child: NesButton(
            type: NesButtonType.normal,
            onPressed: () => _showQueuePanel(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                NesIcon(
                  iconData: NesIcons.gallery,
                  size: const Size.square(16),
                ),
                if (totalCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        totalCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQueuePanel(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<PowBloc>(),
          child: const PixelQueuePanel(),
        ),
      ),
    );
  }
}
