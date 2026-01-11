import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';
import 'package:nostr_place/canvas/view/widgets/color_picker_dialog.dart';

class ColorPickerButton extends StatelessWidget {
  const ColorPickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (previous, current) =>
          previous.selectedColor != current.selectedColor,
      builder: (context, state) {
        return Tooltip(
          message: 'Select color',
          child: GestureDetector(
            onTap: () => _showColorPicker(context, state.selectedColor),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: state.selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.palette, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, Color currentColor) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => ColorPickerDialog(
          initialColor: currentColor,
          onColorSelected: (color) {
            context.read<CanvasBloc>().add(ColorChanged(color));
          },
        ),
      ),
    );
  }
}
