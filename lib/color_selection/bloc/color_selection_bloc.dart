import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'color_selection_event.dart';
part 'color_selection_state.dart';

class ColorSelectionBloc
    extends HydratedBloc<ColorSelectionEvent, ColorSelectionState> {
  ColorSelectionBloc() : super(const ColorSelectionState()) {
    on<ColorSelected>(_onColorSelected);
  }

  void _onColorSelected(
    ColorSelected event,
    Emitter<ColorSelectionState> emit,
  ) {
    emit(state.copyWith(selectedColor: event.color));
  }

  @override
  ColorSelectionState? fromJson(Map<String, dynamic> json) {
    try {
      return ColorSelectionState(
        selectedColor: Color(json['selectedColor'] as int),
      );
    } on Object {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ColorSelectionState state) {
    return {
      'selectedColor': state.selectedColor.toARGB32(),
    };
  }
}
