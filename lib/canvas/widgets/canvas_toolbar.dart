import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/about/about.dart';
import 'package:nostr_canvas/canvas/widgets/color_picker_button.dart';
import 'package:nostr_canvas/canvas/widgets/grid_toggle_button.dart';
import 'package:nostr_canvas/canvas/widgets/inspect_mode_button.dart';
import 'package:nostr_canvas/canvas/widgets/logout_button.dart';
import 'package:nostr_canvas/canvas/widgets/queue_button.dart';
import 'package:nostr_canvas/canvas/widgets/relay_status_indicator.dart';

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return const NesContainer(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorPickerButton(),
          SizedBox(height: 8),
          QueueButton(),
          SizedBox(height: 8),
          InspectModeButton(),
          SizedBox(height: 8),
          GridToggleButton(),
          SizedBox(height: 8),
          RelayStatusIndicator(),
          SizedBox(height: 8),
          InfoButton(),
          SizedBox(height: 8),
          LogoutButton(),
        ],
      ),
    );
  }
}
