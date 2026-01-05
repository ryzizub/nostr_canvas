import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/data/models/models.dart';
import 'package:nostr_place/canvas/game/canvas_game.dart';
import 'package:nostr_place/canvas/game/components/click_highlight_component.dart';
import 'package:nostr_place/canvas/game/components/grid_lines_component.dart';
import 'package:nostr_place/canvas/game/components/pixel_component.dart';

/// Renders the entire pixel grid and handles user interactions.
class PixelGridComponent extends PositionComponent
    with
        FlameBlocListenable<CanvasBloc, CanvasState>,
        TapCallbacks,
        HasGameReference<CanvasGame> {
  PixelGridComponent()
    : super(
        position: Vector2.zero(),
        size: Vector2(100, 100), // 10x10 grid * 10 pixels each
        // Use default topLeft anchor so pixel coordinates map directly to world
      );

  final Map<String, PixelComponent> _pixelComponents = {};
  GridLinesComponent? _gridLines;

  @override
  void onInitialState(CanvasState state) {
    // Handle initial state when component mounts
    if (state is CanvasReady) {
      _updateCanvasSize(state.canvasData);
      _updatePixels(state.canvasData);
    }
  }

  @override
  void onNewState(CanvasState state) {
    if (state is CanvasReady) {
      _updateCanvasSize(state.canvasData);
      _updatePixels(state.canvasData);
    }
  }

  void _updateCanvasSize(CanvasData canvasData) {
    // Update component size to match canvas dimensions
    size = Vector2(
      canvasData.width * 10.0,
      canvasData.height * 10.0,
    );

    // Remove old grid lines and add new ones with correct dimensions
    _gridLines?.removeFromParent();
    _gridLines = GridLinesComponent(
      gridWidth: canvasData.width,
      gridHeight: canvasData.height,
    );
    // Intentionally not awaited - component loads asynchronously
    // ignore: discarded_futures
    add(_gridLines!);
  }

  void _updatePixels(CanvasData canvasData) {
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
        // Intentionally not awaited - components load asynchronously
        // ignore: discarded_futures
        add(pixelComponent);
        _pixelComponents[key] = pixelComponent;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // event.localPosition is already in component's local coordinates
    // Just divide by 10 to get grid position
    final gridX = (event.localPosition.x / 10).floor();
    final gridY = (event.localPosition.y / 10).floor();
    final gridPosition = Position(gridX, gridY);

    // Add visual feedback for the click
    final highlight = ClickHighlightComponent(gridPosition: gridPosition);
    // Intentionally not awaited - component loads asynchronously
    // ignore: discarded_futures
    add(highlight);

    // Place orange pixel
    bloc.add(
      PixelPlaced(
        position: gridPosition,
        color: Colors.orange,
      ),
    );
  }
}
