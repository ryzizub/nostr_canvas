import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/canvas_constants.dart';
import 'package:nostr_place/canvas/game/canvas_game.dart';
import 'package:nostr_place/canvas/game/components/click_highlight_component.dart';
import 'package:nostr_place/canvas/game/components/grid_lines_component.dart';
import 'package:nostr_place/canvas/game/components/pixel_component.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Renders the entire pixel grid and handles user interactions.
class PixelGridComponent extends PositionComponent
    with
        FlameBlocListenable<CanvasBloc, CanvasState>,
        TapCallbacks,
        HasGameReference<CanvasGame> {
  PixelGridComponent()
    : super(
        position: Vector2.zero(),
        // Initial size will be updated when canvas data is loaded
        size: Vector2.zero(),
      );

  final Map<String, PixelComponent> _pixelComponents = {};
  GridLinesComponent? _gridLines;

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
    // Update component size to match canvas dimensions
    size = Vector2(
      canvasData.width * CanvasConstants.tileSize,
      canvasData.height * CanvasConstants.tileSize,
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
          position: pixel.position,
          color: pixel.color,
        );

        await add(pixelComponent);
        _pixelComponents[key] = pixelComponent;
      }
    }
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    // event.localPosition is already in component's local coordinates
    final gridX = (event.localPosition.x / CanvasConstants.tileSize).floor();
    final gridY = (event.localPosition.y / CanvasConstants.tileSize).floor();
    final gridPosition = Position(gridX, gridY);

    // Add visual feedback for the click
    final highlight = ClickHighlightComponent(gridPosition: gridPosition);

    await add(highlight);

    // Place orange pixel
    bloc.add(
      PixelPlaced(
        position: gridPosition,
        color: Colors.orange,
      ),
    );
  }
}
