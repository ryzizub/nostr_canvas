import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/view/canvas_view.dart';
import 'package:pixel_repository/pixel_repository.dart';

/// Entry point page for the canvas feature.
class CanvasPage extends StatelessWidget {
  const CanvasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CanvasBloc(
        pixelRepository: InMemoryPixelRepository(),
      )..add(const CanvasLoadRequested()),
      child: const CanvasView(),
    );
  }
}
