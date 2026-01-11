import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_ui/nes_ui.dart';

/// NES-styled color picker dialog with hex input.
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
    super.key,
  });

  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late TextEditingController _controller;
  late Color _selectedColor;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _controller = TextEditingController(text: _colorToHex(_selectedColor));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '$r$g$b'.toUpperCase();
  }

  Color? _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '').toUpperCase();
    if (cleaned.length != 6) return null;

    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;

    return Color(0xFF000000 + value);
  }

  void _onHexChanged(String value) {
    final color = _hexToColor(value);
    setState(() {
      _isValid = color != null;
      if (color != null) {
        _selectedColor = color;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: NesContainer(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pick a Color',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _ColorPreview(color: _selectedColor),
              const SizedBox(height: 16),
              _HexInput(
                controller: _controller,
                isValid: _isValid,
                onChanged: _onHexChanged,
              ),
              const SizedBox(height: 16),
              _DialogActions(
                isValid: _isValid,
                onCancel: () => Navigator.of(context).pop(),
                onSelect: () {
                  widget.onColorSelected(_selectedColor);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return NesContainer(
      padding: EdgeInsets.zero,
      child: Container(
        width: 80,
        height: 80,
        color: color,
      ),
    );
  }
}

class _HexInput extends StatelessWidget {
  const _HexInput({
    required this.controller,
    required this.isValid,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isValid;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '#',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9A-Fa-f]')),
            ],
            decoration: InputDecoration(
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: const OutlineInputBorder(),
              errorText: isValid ? null : 'Invalid',
            ),
            style: const TextStyle(
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.isValid,
    required this.onCancel,
    required this.onSelect,
  });

  final bool isValid;
  final VoidCallback onCancel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NesButton(
          type: NesButtonType.normal,
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        NesButton(
          type: NesButtonType.primary,
          onPressed: isValid ? onSelect : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}
