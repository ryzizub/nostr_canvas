import 'package:flutter/material.dart';
import 'package:nostr_place/canvas/view/widgets/color_picker_button.dart';
import 'package:nostr_place/canvas/view/widgets/relay_status_indicator.dart';

class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
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
