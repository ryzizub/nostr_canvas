import 'dart:async' show unawaited;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/game/canvas_game.dart';
import 'package:nostr_place/canvas/view/widgets/canvas_toolbar.dart';
import 'package:nostr_place/canvas/view/widgets/pow_progress_dialog.dart';
import 'package:nostr_place/canvas/view/widgets/zoom_controls.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({super.key});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  CanvasGame? _game;
  bool _isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CanvasBloc, CanvasState>(
      listenWhen: (previous, current) =>
          previous.placementProgress != current.placementProgress,
      listener: _handlePlacementProgressChange,
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

  void _handlePlacementProgressChange(BuildContext context, CanvasState state) {
    final progress = state.placementProgress;

    if (progress != null && !_isDialogShowing) {
      // Show dialog
      _isDialogShowing = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => BlocBuilder<CanvasBloc, CanvasState>(
            bloc: context.read<CanvasBloc>(),
            buildWhen: (previous, current) =>
                previous.placementProgress != current.placementProgress,
            builder: (dialogContext, dialogState) {
              final dialogProgress = dialogState.placementProgress;
              if (dialogProgress == null) {
                // Close dialog if progress is null
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
                onDismiss: () {
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
    _game ??= CanvasGame(canvasBloc: context.read<CanvasBloc>());

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
}
