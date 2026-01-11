import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/core/constants.dart';

class ZoomControls extends StatelessWidget {
  const ZoomControls({super.key});

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (previous, current) => previous.zoomLevel != current.zoomLevel,
      builder: (context, state) {
        return NesContainer(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NesIconButton(
                icon: NesIcons.zoomIn,
                onPress: () => _zoomIn(context, state.zoomLevel),
              ),
              const SizedBox(height: 8),
              NesIconButton(
                icon: NesIcons.zoomOut,
                onPress: () => _zoomOut(context, state.zoomLevel),
              ),
            ],
          ),
        );
      },
    );
  }
}
