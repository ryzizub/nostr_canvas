import 'dart:async' show unawaited;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:nostr_canvas/canvas/game/components/queued_pixel_component.dart';
import 'package:nostr_canvas/pow/pow.dart';

/// Layer component that renders queued pixels.
/// Listens to PowBloc and updates visual representation of the queue.
class QueuedPixelsLayer extends PositionComponent
    with FlameBlocListenable<PowBloc, PowState> {
  QueuedPixelsLayer() : super(position: Vector2.zero());

  final Map<String, QueuedPixelComponent> _queuedComponents = {};
  QueuedPixelComponent? _currentPixelComponent;

  @override
  bool listenWhen(PowState previousState, PowState newState) {
    return previousState.queue != newState.queue ||
        previousState.currentPixel != newState.currentPixel;
  }

  @override
  void onInitialState(PowState state) {
    unawaited(_updateQueuedPixels(state));
  }

  @override
  void onNewState(PowState state) {
    unawaited(_updateQueuedPixels(state));
  }

  Future<void> _updateQueuedPixels(PowState state) async {
    // Build set of current queue pixel IDs
    final currentIds = <String>{};
    for (final pixel in state.queue) {
      currentIds.add(pixel.id);
    }
    if (state.currentPixel != null) {
      currentIds.add(state.currentPixel!.id);
    }

    // Remove components no longer in queue
    _queuedComponents.removeWhere((id, component) {
      if (!currentIds.contains(id)) {
        component.removeFromParent();
        return true;
      }
      return false;
    });

    // Remove old current pixel component if it changed
    if (_currentPixelComponent != null &&
        (state.currentPixel == null ||
            state.currentPixel!.id != _currentPixelComponent!.queuedPixel.id)) {
      _currentPixelComponent?.removeFromParent();
      _currentPixelComponent = null;
    }

    // Add current pixel component (processing)
    if (state.currentPixel != null && _currentPixelComponent == null) {
      _currentPixelComponent = QueuedPixelComponent(
        queuedPixel: state.currentPixel!,
        queuePosition: 0,
        isProcessing: true,
      );
      await add(_currentPixelComponent!);
    }

    // Update or add queued pixel components
    for (var i = 0; i < state.queue.length; i++) {
      final pixel = state.queue[i];
      final queuePosition = i + 1;

      if (_queuedComponents.containsKey(pixel.id)) {
        // Component exists - check if position changed
        final existing = _queuedComponents[pixel.id]!;
        if (existing.queuePosition != queuePosition) {
          // Position changed, recreate component
          existing.removeFromParent();
          final newComponent = QueuedPixelComponent(
            queuedPixel: pixel,
            queuePosition: queuePosition,
          );
          await add(newComponent);
          _queuedComponents[pixel.id] = newComponent;
        }
      } else {
        // Add new component
        final component = QueuedPixelComponent(
          queuedPixel: pixel,
          queuePosition: queuePosition,
        );
        await add(component);
        _queuedComponents[pixel.id] = component;
      }
    }
  }
}
