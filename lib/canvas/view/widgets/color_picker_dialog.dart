import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

/// NES-styled color picker dialog with a grid of preset colors.
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
  late Color _selectedColor;

  /// Classic pixel art color palette.
  static const List<Color> _colors = [
    // Row 1: Blacks, grays, whites
    Color(0xFF000000), // Black
    Color(0xFF1D2B53), // Dark blue-gray
    Color(0xFF7E2553), // Dark magenta
    Color(0xFF008751), // Dark green
    Color(0xFFAB5236), // Brown
    Color(0xFF5F574F), // Dark gray
    Color(0xFFC2C3C7), // Light gray
    Color(0xFFFFF1E8), // White

    // Row 2: Reds and oranges
    Color(0xFFFF004D), // Red
    Color(0xFFFFA300), // Orange
    Color(0xFFFFEC27), // Yellow
    Color(0xFF00E436), // Green
    Color(0xFF29ADFF), // Light blue
    Color(0xFF83769C), // Purple gray
    Color(0xFFFF77A8), // Pink
    Color(0xFFFFCCAA), // Peach

    // Row 3: Additional colors
    Color(0xFF1E1E1E), // Near black
    Color(0xFF3B3B3B), // Charcoal
    Color(0xFF5A5A5A), // Medium gray
    Color(0xFF7B7B7B), // Gray
    Color(0xFF9E9E9E), // Silver
    Color(0xFFBDBDBD), // Light silver
    Color(0xFFE0E0E0), // Very light gray
    Color(0xFFFFFFFF), // Pure white

    // Row 4: Extended palette
    Color(0xFF8B0000), // Dark red
    Color(0xFFFF6B6B), // Coral
    Color(0xFF4ECDC4), // Teal
    Color(0xFF2ECC71), // Emerald
    Color(0xFF3498DB), // Sky blue
    Color(0xFF9B59B6), // Amethyst
    Color(0xFFE91E63), // Rose
    Color(0xFFFF9800), // Amber
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: NesContainer(
          width: 340,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pick a Color',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildColorGrid(),
              const SizedBox(height: 16),
              _buildSelectedColorPreview(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: _colors.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: NesContainer(
            padding: EdgeInsets.zero,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedColorPreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Selected: '),
        const SizedBox(width: 8),
        NesContainer(
          padding: EdgeInsets.zero,
          child: Container(
            width: 48,
            height: 48,
            color: _selectedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NesButton(
          type: NesButtonType.normal,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        NesButton(
          type: NesButtonType.primary,
          onPressed: () {
            widget.onColorSelected(_selectedColor);
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
