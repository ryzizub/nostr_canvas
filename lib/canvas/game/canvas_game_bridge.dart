import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/game/canvas_game.dart';

/// Bridges Flutter bloc events to Flame game commands.
class CanvasGameBridge {
  CanvasGameBridge({
    required this.game,
    required this.bloc,
  });

  final CanvasGame game;
  final CanvasBloc bloc;

  /// Sync zoom from Flutter UI to Flame camera.
  void updateZoom(double zoom) {
    game.zoom = zoom;
    bloc.add(ZoomChanged(zoom));
  }

  /// Sync pan from Flutter UI to Flame camera.
  void updatePan(Offset offset) {
    game.panCamera(offset);
    bloc.add(CanvasPanned(offset));
  }
}
