import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/color_picker/color_picker.dart';
import 'package:nostr_place/color_selection/color_selection.dart';

class ColorPickerButton extends StatelessWidget {
  const ColorPickerButton({super.key});

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _showColorPicker(BuildContext context, Color currentColor) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => ColorPickerDialog(
          initialColor: currentColor,
          onColorSelected: (color) {
            context.read<ColorSelectionBloc>().add(ColorSelected(color));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ColorSelectionBloc, ColorSelectionState>(
      buildWhen: (previous, current) =>
          previous.selectedColor != current.selectedColor,
      builder: (context, state) {
        return Tooltip(
          message: 'Select color',
          preferBelow: false,
          child: GestureDetector(
            onTap: () => _showColorPicker(context, state.selectedColor),
            child: NesContainer(
              padding: const EdgeInsets.all(8),
              backgroundColor: state.selectedColor,
              child: NesIcon(
                iconData: NesIcons.gallery,
                primaryColor: _getContrastColor(state.selectedColor),
              ),
            ),
          ),
        );
      },
    );
  }
}
