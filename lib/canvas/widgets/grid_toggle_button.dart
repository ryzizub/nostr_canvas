import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_canvas/canvas/bloc/canvas_bloc.dart';

class GridToggleButton extends StatelessWidget {
  const GridToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (previous, current) =>
          previous.gridEnabled != current.gridEnabled,
      builder: (context, state) {
        return Tooltip(
          message: state.gridEnabled ? 'Hide grid' : 'Show grid',
          preferBelow: false,
          child: GestureDetector(
            onTap: () => context.read<CanvasBloc>().add(const GridToggled()),
            child: NesContainer(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  // Use NesIcon for sizing reference
                  Opacity(
                    opacity: 0,
                    child: NesIcon(iconData: NesIcons.block),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridIconPainter(
                        color: state.gridEnabled ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridIconPainter extends CustomPainter {
  _GridIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw 3x3 grid lines
    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    canvas
      // Vertical lines
      ..drawLine(
        Offset(cellWidth, 0),
        Offset(cellWidth, size.height),
        paint,
      )
      ..drawLine(
        Offset(cellWidth * 2, 0),
        Offset(cellWidth * 2, size.height),
        paint,
      )
      // Horizontal lines
      ..drawLine(
        Offset(0, cellHeight),
        Offset(size.width, cellHeight),
        paint,
      )
      ..drawLine(
        Offset(0, cellHeight * 2),
        Offset(size.width, cellHeight * 2),
        paint,
      );
  }

  @override
  bool shouldRepaint(_GridIconPainter oldDelegate) =>
      color != oldDelegate.color;
}
