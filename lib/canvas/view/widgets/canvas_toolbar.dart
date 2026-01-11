import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/canvas/view/widgets/color_picker_button.dart';
import 'package:nostr_place/canvas/view/widgets/relay_status_indicator.dart';

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
          RelayStatusIndicator(),
        ],
      ),
    );
  }
}
