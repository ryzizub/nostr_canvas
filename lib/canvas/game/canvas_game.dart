import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/game/components/pixel_grid_component.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Main FlameGame for the pixel canvas.
class CanvasGame extends FlameGame with PanDetector, ScrollDetector {
  CanvasGame({required this.canvasBloc});

  final CanvasBloc canvasBloc;
  CameraComponent? _cameraComponent;

  // Pan threshold to distinguish taps from drags
  static const double _panThreshold = 5;
  Vector2? _panStartPosition;
  bool _isPanning = false;

  @override
  CameraComponent get camera {
    if (_cameraComponent == null) {
      _cameraComponent = super.camera;
      // Set viewfinder anchor to center to look at world center
      _cameraComponent!.viewfinder.anchor = Anchor.center;
    }
    return _cameraComponent!;
  }

  @override
  Color backgroundColor() => Colors.white;

  bool _initialCameraSet = false;

  @override
  Future<void> onLoad() async {
    // Camera anchors are set via getter override, no need to set here

    // Add the pixel grid component to the world (not game) so camera affects it
    await world.add(
      FlameBlocProvider<CanvasBloc, CanvasState>(
        create: () => canvasBloc,
        children: [
          PixelGridComponent(),
        ],
      ),
    );

    // Handle initial state if already ready
    final currentState = canvasBloc.state;
    if (currentState is CanvasReady) {
      _updateCameraForCanvas(currentState.canvasData);
    } else {
      // Wait for canvas to be ready (intentionally not awaited)
      unawaited(
        canvasBloc.stream.firstWhere((s) => s is CanvasReady).then((state) {
          if (state is CanvasReady) {
            _updateCameraForCanvas(state.canvasData);
          }
        }),
      );
    }
  }

  @override
  void onPanStart(DragStartInfo info) {
    final pos = info.raw.globalPosition;
    _panStartPosition = Vector2(pos.dx, pos.dy);
    _isPanning = false;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_panStartPosition == null) return;

    final currentPos = Vector2(
      info.raw.globalPosition.dx,
      info.raw.globalPosition.dy,
    );
    final totalDelta = currentPos - _panStartPosition!;

    // Only start panning if threshold exceeded
    if (!_isPanning && totalDelta.length > _panThreshold) {
      _isPanning = true;
    }

    if (_isPanning) {
      // Move camera opposite to drag direction, scaled by zoom
      final delta = info.delta.global;
      final scaledDelta = Vector2(delta.x, delta.y) / camera.viewfinder.zoom;
      camera.viewfinder.position -= scaledDelta;
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _panStartPosition = null;
    _isPanning = false;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    // Scroll up (negative) = zoom in, scroll down (positive) = zoom out
    final scrollDelta = info.scrollDelta.global.y;
    final zoomFactor = scrollDelta > 0 ? 0.9 : 1.1;
    final newZoom = (camera.viewfinder.zoom * zoomFactor).clamp(0.1, 100.0);
    camera.viewfinder.zoom = newZoom;
  }

  /// Sets up initial camera position and zoom. Only runs once.
  void _updateCameraForCanvas(CanvasData canvasData) {
    if (_initialCameraSet) return;

    if (hasLayout) {
      // Set initial position to center of canvas
      final centerX = canvasData.width * 10.0 / 2;
      final centerY = canvasData.height * 10.0 / 2;
      camera.viewfinder.position = Vector2(centerX, centerY);

      // Set initial zoom
      _updateZoom(size);
      _initialCameraSet = true;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Update camera position and zoom when screen resizes
    final state = canvasBloc.state;
    if (state is CanvasReady) {
      _updateCameraForCanvas(state.canvasData);
    }
  }

  void _updateZoom(Vector2 screenSize) {
    final state = canvasBloc.state;
    if (state is! CanvasReady) return;

    final canvasHeightInPixels = state.canvasData.height;
    final targetPixelsToShow = canvasHeightInPixels < 50
        ? canvasHeightInPixels
        : 50;

    // Each pixel is 10 units in world space
    final worldHeight = targetPixelsToShow * 10.0;

    // Calculate zoom to show target pixels vertically (with 90% padding)
    camera.viewfinder.zoom = (screenSize.y * 0.9) / worldHeight;
  }

  /// Convert screen tap to grid position.
  Position screenToGridPosition(Vector2 screenPosition) {
    final worldPosition = camera.globalToLocal(screenPosition);
    // Each pixel is 10x10 units, so divide by 10 to get grid coordinates
    final gridX = (worldPosition.x / 10).floor();
    final gridY = (worldPosition.y / 10).floor();

    return Position(gridX, gridY);
  }

  double get zoom => camera.viewfinder.zoom;

  set zoom(double value) {
    camera.viewfinder.zoom = value;
  }

  void panCamera(Offset offset) {
    camera.viewfinder.position += Vector2(offset.dx, offset.dy);
  }
}
