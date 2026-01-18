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
  bool _isDialogShowing = false;
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

  void _handlePowStateChange(BuildContext context, PowState state) {
    if (state.status != PowStatus.idle && !_isDialogShowing) {
      // Show dialog
      _isDialogShowing = true;
      final powBloc = context.read<PowBloc>();
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => BlocBuilder<PowBloc, PowState>(
            bloc: powBloc,
            builder: (dialogContext, dialogState) {
              final dialogProgress = dialogState.progress;
              if (dialogProgress == null ||
                  dialogState.status == PowStatus.idle) {
                // Close dialog if progress is null or idle
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_isDialogShowing) {
                    Navigator.of(context).pop();
                    _isDialogShowing = false;
                  }
                });
                return const SizedBox.shrink();
              }
              return PowProgressDialog(
                progress: dialogProgress,
                queueLength: dialogState.queueLength,
                onDismiss: () {
                  powBloc.add(const PowDismissed());
                  Navigator.of(context).pop();
                  _isDialogShowing = false;
                },
                onRetry: () {
                  powBloc.add(const PowQueueRetried());
                },
                onSkip: () {
                  powBloc.add(const PowQueueSkipped());
                },
                onClearQueue: () {
                  powBloc.add(const PowQueueCleared());
                  Navigator.of(context).pop();
                  _isDialogShowing = false;
                },
              );
            },
          ),
        ).then((_) {
          _isDialogShowing = false;
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PowBloc, PowState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _handlePowStateChange,
        ),
        BlocListener<CanvasBloc, CanvasState>(
          listenWhen: (previous, current) =>
              previous.inspectedPixel != current.inspectedPixel,
          listener: _handleInspectStateChange,
        ),
      ],
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
