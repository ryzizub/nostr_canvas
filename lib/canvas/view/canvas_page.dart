import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_canvas/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_canvas/canvas/bloc/relay_bloc.dart';
import 'package:nostr_canvas/canvas/view/canvas_view.dart';
import 'package:nostr_canvas/color_selection/color_selection.dart';
import 'package:nostr_canvas/pow/pow.dart';
import 'package:pixel_repository/pixel_repository.dart';
import 'package:relay_settings_repository/relay_settings_repository.dart';

/// Entry point page for the canvas feature.
///
/// Expects PixelRepository to be provided by a parent widget.
class CanvasPage extends StatelessWidget {
  const CanvasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CanvasBloc(
            pixelRepository: context.read<PixelRepository>(),
          )..add(const CanvasLoadRequested()),
        ),
        BlocProvider(
          create: (context) => PowBloc(
            pixelRepository: context.read<PixelRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => RelayBloc(
            pixelRepository: context.read<PixelRepository>(),
            relaySettingsRepository: context.read<RelaySettingsRepository>(),
          )..add(const RelaySubscriptionRequested()),
        ),
        BlocProvider(create: (_) => ColorSelectionBloc()),
      ],
      child: const CanvasView(),
    );
  }
}
