import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/canvas_constants.dart';
import 'package:nostr_place/canvas/game/components/camera_controller_component.dart';
import 'package:nostr_place/canvas/game/components/pixel_grid_component.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Main FlameGame for the pixel canvas.
class CanvasGame extends FlameGame with PanDetector, ScrollDetector {
  CanvasGame({required this.canvasBloc});

  final CanvasBloc canvasBloc;
  CameraComponent? _cameraComponent;

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

    // Add components to the world (not game) so camera affects them
    await world.add(
      FlameBlocProvider<CanvasBloc, CanvasState>(
        create: () => canvasBloc,
        children: [
          PixelGridComponent(),
          CameraControllerComponent(),
        ],
      ),
    );

    // Handle initial state if already ready
    final currentState = canvasBloc.state;
    if (currentState.status == CanvasStatus.ready) {
      _updateCameraForCanvas(currentState.canvasData!);
    } else {
      // Wait for canvas to be ready (intentionally not awaited)
      unawaited(
        canvasBloc.stream
            .firstWhere((s) => s.status == CanvasStatus.ready)
            .then((state) {
          _updateCameraForCanvas(state.canvasData!);
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
    if (!_isPanning && totalDelta.length > CanvasConstants.panThreshold) {
      _isPanning = true;
    }

    if (_isPanning) {
      // Move camera opposite to drag direction, scaled by zoom
      final delta = info.delta.global;
      final scaledDelta = Vector2(delta.x, delta.y) / camera.viewfinder.zoom;
      final newPosition = camera.viewfinder.position - scaledDelta;

      // Dispatch event - CameraControllerComponent will apply
      canvasBloc.add(
        CameraPositionChanged(Offset(newPosition.x, newPosition.y)),
      );
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
    final zoomFactor = scrollDelta > 0
        ? CanvasConstants.scrollZoomOutFactor
        : CanvasConstants.scrollZoomInFactor;
    final newZoom = (camera.viewfinder.zoom * zoomFactor).clamp(
      CanvasConstants.minZoom,
      CanvasConstants.maxZoom,
    );

    // Dispatch event - CameraControllerComponent will apply
    canvasBloc.add(ZoomChanged(newZoom));
  }

  /// Sets up initial camera position and zoom. Only runs once.
  void _updateCameraForCanvas(CanvasData canvasData) {
    if (_initialCameraSet) return;

    if (hasLayout) {
      // Calculate center of canvas
      final centerX = canvasData.width * CanvasConstants.tileSize / 2;
      final centerY = canvasData.height * CanvasConstants.tileSize / 2;

      // Calculate initial zoom
      final initialZoom = _calculateInitialZoom(size, canvasData);

      // Dispatch events - CameraControllerComponent will apply
      canvasBloc
        ..add(CameraPositionChanged(Offset(centerX, centerY)))
        ..add(ZoomChanged(initialZoom));

      _initialCameraSet = true;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Update camera position and zoom when screen resizes
    final state = canvasBloc.state;
    if (state.status == CanvasStatus.ready) {
      _updateCameraForCanvas(state.canvasData!);
    }
  }

  double _calculateInitialZoom(Vector2 screenSize, CanvasData canvasData) {
    final canvasHeightInPixels = canvasData.height;
    final targetPixels =
        canvasHeightInPixels < CanvasConstants.targetPixelsToShow
            ? canvasHeightInPixels
            : CanvasConstants.targetPixelsToShow;

    final worldHeight = targetPixels * CanvasConstants.tileSize;

    // Calculate zoom to show target pixels vertically (with padding)
    return (screenSize.y * CanvasConstants.zoomPaddingFactor) / worldHeight;
  }

  /// Convert screen tap to grid position.
  Position screenToGridPosition(Vector2 screenPosition) {
    final worldPosition = camera.globalToLocal(screenPosition);
    final gridX = (worldPosition.x / CanvasConstants.tileSize).floor();
    final gridY = (worldPosition.y / CanvasConstants.tileSize).floor();

    return Position(gridX, gridY);
  }

}
