part of 'color_selection_bloc.dart';

sealed class ColorSelectionEvent {
  const ColorSelectionEvent();
}

final class ColorSelected extends ColorSelectionEvent {
  const ColorSelected(this.color);

  final Color color;
}
