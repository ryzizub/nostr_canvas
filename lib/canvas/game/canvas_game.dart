import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/game/components/camera_controller_component.dart';
import 'package:nostr_place/canvas/game/components/pixel_grid_component.dart';
import 'package:nostr_place/color_selection/color_selection.dart';
import 'package:nostr_place/core/constants.dart';
import 'package:nostr_place/pow/pow.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Main FlameGame for the pixel canvas.
class CanvasGame extends FlameGame with PanDetector, ScrollDetector {
  CanvasGame({
    required this.canvasBloc,
    required this.powBloc,
    required this.colorSelectionBloc,
  });

  final CanvasBloc canvasBloc;
  final PowBloc powBloc;
  final ColorSelectionBloc colorSelectionBloc;
  CameraComponent? _cameraComponent;

  Vector2? _panStartPosition;
  Vector2? _panStartScreenPosition;
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
      FlameMultiBlocProvider(
        providers: [
          FlameBlocProvider<CanvasBloc, CanvasState>.value(value: canvasBloc),
          FlameBlocProvider<PowBloc, PowState>.value(value: powBloc),
          FlameBlocProvider<ColorSelectionBloc, ColorSelectionState>.value(
            value: colorSelectionBloc,
          ),
        ],
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
    _panStartScreenPosition = Vector2(
      info.raw.localPosition.dx,
      info.raw.localPosition.dy,
    );
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
    if (!_isPanning && totalDelta.length > Constants.panThreshold) {
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
    // If we weren't panning, treat this as a tap
    if (!_isPanning && _panStartScreenPosition != null) {
      _handleTap(_panStartScreenPosition!);
    }
    _panStartPosition = null;
    _panStartScreenPosition = null;
    _isPanning = false;
  }

  void _handleTap(Vector2 screenPosition) {
    final gridPosition = screenToGridPosition(screenPosition);

    // Validate tap is within canvas bounds
    final state = canvasBloc.state;
    if (state.status != CanvasStatus.ready) return;

    final canvasData = state.canvasData!;
    if (gridPosition.x < 0 ||
        gridPosition.x >= canvasData.width ||
        gridPosition.y < 0 ||
        gridPosition.y >= canvasData.height) {
      return;
    }

    // Add click highlight
    final pixelGrid = world.descendants().whereType<PixelGridComponent>().first;
    unawaited(pixelGrid.addClickHighlight(gridPosition.x, gridPosition.y));

    // Place pixel via PowBloc
    powBloc.add(
      PowPlacePixelRequested(
        position: gridPosition,
        color: colorSelectionBloc.state.selectedColor,
      ),
    );
  }

  @override
  void onScroll(PointerScrollInfo info) {
    // Scroll up (negative) = zoom in, scroll down (positive) = zoom out
    final scrollDelta = info.scrollDelta.global.y;
    final zoomFactor = scrollDelta > 0
        ? Constants.scrollZoomOutFactor
        : Constants.scrollZoomInFactor;
    final newZoom = (camera.viewfinder.zoom * zoomFactor).clamp(
      Constants.minZoom,
      Constants.maxZoom,
    );

    // Dispatch event - CameraControllerComponent will apply
    canvasBloc.add(ZoomChanged(newZoom));
  }

  /// Sets up initial camera position and zoom. Only runs once.
  void _updateCameraForCanvas(CanvasData canvasData) {
    if (_initialCameraSet) return;

    if (hasLayout) {
      // Calculate center of canvas
      final centerX = canvasData.width * Constants.tileSize / 2;
      final centerY = canvasData.height * Constants.tileSize / 2;

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
    final targetPixels = canvasHeightInPixels < Constants.targetPixelsToShow
        ? canvasHeightInPixels
        : Constants.targetPixelsToShow;

    final worldHeight = targetPixels * Constants.tileSize;

    // Calculate zoom to show target pixels vertically (with padding)
    return (screenSize.y * Constants.zoomPaddingFactor) / worldHeight;
  }

  /// Convert screen tap to grid position.
  Position screenToGridPosition(Vector2 screenPosition) {
    final worldPosition = camera.globalToLocal(screenPosition);
    final gridX = (worldPosition.x / Constants.tileSize).floor();
    final gridY = (worldPosition.y / Constants.tileSize).floor();

    return Position(gridX, gridY);
  }
}
