part of 'color_selection_bloc.dart';

final class ColorSelectionState {
  const ColorSelectionState({
    this.selectedColor = Colors.orange,
  });

  final Color selectedColor;

  ColorSelectionState copyWith({
    Color? selectedColor,
  }) {
    return ColorSelectionState(
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }
}
