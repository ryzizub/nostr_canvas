import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/data/repositories/pixel_repository.dart';
import 'package:nostr_place/canvas/view/canvas_view.dart';

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
