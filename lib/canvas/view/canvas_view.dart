import 'dart:async' show unawaited;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_canvas/canvas/game/canvas_game.dart';
import 'package:nostr_canvas/canvas/widgets/canvas_toolbar.dart';
import 'package:nostr_canvas/canvas/widgets/pixel_info_dialog.dart';
import 'package:nostr_canvas/canvas/widgets/zoom_controls.dart';
import 'package:nostr_canvas/color_selection/color_selection.dart';
import 'package:nostr_canvas/pow/pow.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({super.key});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  CanvasGame? _game;
  bool _isInspectDialogShowing = false;

  void _handleInspectStateChange(BuildContext context, CanvasState state) {
    if (state.inspectedPixel != null && !_isInspectDialogShowing) {
      _isInspectDialogShowing = true;
      final canvasBloc = context.read<CanvasBloc>();
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => PixelInfoDialog(pixel: state.inspectedPixel!),
        ).then((_) {
          _isInspectDialogShowing = false;
          canvasBloc.add(const PixelInspectDismissed());
        }),
      );
    }
  }

  Widget _buildCanvas(BuildContext context) {
    _game ??= CanvasGame(
      canvasBloc: context.read<CanvasBloc>(),
      powBloc: context.read<PowBloc>(),
      colorSelectionBloc: context.read<ColorSelectionBloc>(),
    );

    return Stack(
      children: [
        GameWidget(game: _game!),
        const Positioned(
          left: 16,
          bottom: 16,
          child: CanvasToolbar(),
        ),
        const Positioned(
          right: 16,
          bottom: 16,
          child: ZoomControls(),
        ),
        const Positioned(
          top: 16,
          right: 16,
          child: MiningIndicator(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CanvasBloc, CanvasState>(
      listenWhen: (previous, current) =>
          previous.inspectedPixel != current.inspectedPixel,
      listener: _handleInspectStateChange,
      child: Scaffold(
        body: BlocBuilder<CanvasBloc, CanvasState>(
          builder: (context, state) {
            return switch (state.status) {
              CanvasStatus.initial => const SizedBox.shrink(),
              CanvasStatus.loading => const Center(
                child: NesHourglassLoadingIndicator(),
              ),
              CanvasStatus.error => Center(
                child: NesContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NesIcon(
                        iconData: NesIcons.exclamationMarkBlock,
                        primaryColor: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: ${state.errorMessage}'),
                    ],
                  ),
                ),
              ),
              CanvasStatus.ready => _buildCanvas(context),
            };
          },
        ),
      ),
    );
  }
}
