import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/canvas/bloc/canvas_bloc.dart';

class InspectModeButton extends StatelessWidget {
  const InspectModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (previous, current) =>
          previous.inspectModeEnabled != current.inspectModeEnabled,
      builder: (context, state) {
        final message = state.inspectModeEnabled
            ? 'Exit inspect mode'
            : 'Inspect pixel';
        return Tooltip(
          message: message,
          preferBelow: false,
          child: GestureDetector(
            onTap: () =>
                context.read<CanvasBloc>().add(const InspectModeToggled()),
            child: NesContainer(
              padding: const EdgeInsets.all(8),
              child: NesIcon(
                iconData: NesIcons.openEye,
                primaryColor: state.inspectModeEnabled ? Colors.blue : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
