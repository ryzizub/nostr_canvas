import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/game/canvas_game.dart';
import 'package:nostr_place/canvas/view/widgets/zoom_controls.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({super.key});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  CanvasGame? _game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Place'),
      ),
      body: BlocBuilder<CanvasBloc, CanvasState>(
        builder: (context, state) {
          return switch (state.status) {
            CanvasStatus.initial => const SizedBox.shrink(),
            CanvasStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
            CanvasStatus.error => Center(
                child: Text('Error: ${state.errorMessage}'),
              ),
            CanvasStatus.ready => _buildCanvas(context),
          };
        },
      ),
    );
  }

  Widget _buildCanvas(BuildContext context) {
    _game ??= CanvasGame(canvasBloc: context.read<CanvasBloc>());

    return Stack(
      children: [
        GameWidget(game: _game!),
        const Positioned(
          right: 16,
          bottom: 16,
          child: ZoomControls(),
        ),
      ],
    );
  }
}
