import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/game/canvas_game.dart';

/// Syncs camera state from bloc to Flame camera.
///
/// This component listens to CanvasState and applies zoom/position
/// changes to the game camera, making the bloc the single source of truth.
class CameraControllerComponent extends Component
    with
        FlameBlocListenable<CanvasBloc, CanvasState>,
        HasGameReference<CanvasGame> {
  @override
  bool listenWhen(CanvasState previousState, CanvasState newState) {
    return previousState.zoomLevel != newState.zoomLevel ||
        previousState.cameraPosition != newState.cameraPosition;
  }

  @override
  void onInitialState(CanvasState state) {
    _applyState(state);
  }

  @override
  void onNewState(CanvasState state) {
    _applyState(state);
  }

  void _applyState(CanvasState state) {
    game.camera.viewfinder.zoom = state.zoomLevel;
    game.camera.viewfinder.position = Vector2(
      state.cameraPosition.dx,
      state.cameraPosition.dy,
    );
  }
}
