import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_place/app/constants.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';

class ZoomControls extends StatelessWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (previous, current) => previous.zoomLevel != current.zoomLevel,
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'zoom_in',
              onPressed: () => _zoomIn(context, state.zoomLevel),
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'zoom_out',
              onPressed: () => _zoomOut(context, state.zoomLevel),
              child: const Icon(Icons.remove),
            ),
          ],
        );
      },
    );
  }

  void _zoomIn(BuildContext context, double currentZoom) {
    final newZoom = (currentZoom * Constants.zoomInFactor).clamp(
      Constants.minZoom,
      Constants.maxZoom,
    );
    context.read<CanvasBloc>().add(ZoomChanged(newZoom));
  }

  void _zoomOut(BuildContext context, double currentZoom) {
    final newZoom = (currentZoom / Constants.zoomInFactor).clamp(
      Constants.minZoom,
      Constants.maxZoom,
    );
    context.read<CanvasBloc>().add(ZoomChanged(newZoom));
  }
}
