import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/about/widgets/about_dialog.dart';

/// A button that opens the AboutDialog when pressed.
class InfoButton extends StatelessWidget {
  const InfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'About Nostr Canvas',
      child: NesIconButton(
        icon: NesIcons.questionMarkBlock,
        onPress: () => _showAboutDialog(context),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => const AppInfoDialog(),
      ),
    );
  }
}
