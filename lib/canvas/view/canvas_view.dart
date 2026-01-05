import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/game/canvas_game.dart';
import 'package:nostr_place/canvas/game/canvas_game_bridge.dart';
import 'package:nostr_place/canvas/view/widgets/zoom_controls.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({super.key});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  CanvasGame? _game;
  CanvasGameBridge? _bridge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Place'),
      ),
      body: BlocBuilder<CanvasBloc, CanvasState>(
        builder: (context, state) {
          if (state is CanvasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CanvasError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is CanvasReady) {
            // Create game only once when canvas is ready
            _game ??= CanvasGame(canvasBloc: context.read<CanvasBloc>());
            _bridge ??= CanvasGameBridge(
              game: _game!,
              bloc: context.read<CanvasBloc>(),
            );

            return Stack(
              children: [
                GameWidget(game: _game!),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: ZoomControls(bridge: _bridge!),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
