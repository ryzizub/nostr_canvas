import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/game/canvas_game.dart';
import 'package:nostr_place/canvas/game/components/click_highlight_component.dart';
import 'package:nostr_place/canvas/game/components/grid_lines_component.dart';
import 'package:nostr_place/canvas/game/components/pixel_component.dart';
import 'package:nostr_place/core/constants.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Renders the entire pixel grid and handles user interactions.
class PixelGridComponent extends PositionComponent
    with
        FlameBlocListenable<CanvasBloc, CanvasState>,
        HasGameReference<CanvasGame> {
  PixelGridComponent()
    : super(
        position: Vector2.zero(),
        // Initial size will be updated when canvas data is loaded
        size: Vector2.zero(),
      );

  final Map<String, PixelComponent> _pixelComponents = {};
  GridLinesComponent? _gridLines;
  int _currentGridWidth = 0;
  int _currentGridHeight = 0;

  @override
  bool listenWhen(CanvasState previousState, CanvasState newState) {
    return previousState.canvasData != newState.canvasData;
  }

  @override
  void onInitialState(CanvasState state) {
    // Handle initial state when component mounts
    if (state.status == CanvasStatus.ready) {
      unawaited(_updateCanvasSize(state.canvasData!));
      unawaited(_updatePixels(state.canvasData!));
    }
  }

  @override
  void onNewState(CanvasState state) {
    if (state.status == CanvasStatus.ready) {
      unawaited(_updateCanvasSize(state.canvasData!));
      unawaited(_updatePixels(state.canvasData!));
    }
  }

  Future<void> _updateCanvasSize(CanvasData canvasData) async {
    // Skip if dimensions haven't changed
    if (_currentGridWidth == canvasData.width &&
        _currentGridHeight == canvasData.height) {
      return;
    }

    _currentGridWidth = canvasData.width;
    _currentGridHeight = canvasData.height;

    // Update component size to match canvas dimensions
    size = Vector2(
      canvasData.width * Constants.tileSize,
      canvasData.height * Constants.tileSize,
    );

    // Remove old grid lines and add new ones with correct dimensions
    _gridLines?.removeFromParent();
    _gridLines = GridLinesComponent(
      gridWidth: canvasData.width,
      gridHeight: canvasData.height,
    );

    await add(_gridLines!);
  }

  Future<void> _updatePixels(CanvasData canvasData) async {
    // Remove old pixels not in new data
    _pixelComponents.removeWhere((key, component) {
      if (!canvasData.pixels.containsKey(key)) {
        component.removeFromParent();
        return true;
      }
      return false;
    });

    // Add or update pixels
    for (final entry in canvasData.pixels.entries) {
      final key = entry.key;
      final pixel = entry.value;

      if (_pixelComponents.containsKey(key)) {
        // Update existing pixel color
        _pixelComponents[key]!.color = pixel.color;
      } else {
        // Add new pixel
        final pixelComponent = PixelComponent(
          x: pixel.position.x,
          y: pixel.position.y,
          color: pixel.color,
        );

        await add(pixelComponent);
        _pixelComponents[key] = pixelComponent;
      }
    }
  }

  /// Adds a click highlight at the given grid position.
  Future<void> addClickHighlight(int gridX, int gridY) async {
    final highlight = ClickHighlightComponent(x: gridX, y: gridY);
    await add(highlight);
  }
}
