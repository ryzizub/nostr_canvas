import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/canvas/bloc/canvas_bloc.dart';

class InspectModeButton extends StatelessWidget {
  const InspectModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasBloc, CanvasState>(
      buildWhen: (previous, current) =>
          previous.inspectModeEnabled != current.inspectModeEnabled,
      builder: (context, state) {
        final message = state.inspectModeEnabled
            ? 'Exit inspect mode'
            : 'Inspect pixel';
        final iconColor =
            state.inspectModeEnabled ? Colors.blue : Colors.white;
        return Tooltip(
          message: message,
          preferBelow: false,
          child: GestureDetector(
            onTap: () =>
                context.read<CanvasBloc>().add(const InspectModeToggled()),
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
                      painter: _InspectIconPainter(color: iconColor),
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

class _InspectIconPainter extends CustomPainter {
  _InspectIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw magnifying glass circle
    final circleRadius = size.width * 0.3;
    final circleCenter = Offset(size.width * 0.35, size.height * 0.35);

    // Draw handle
    final handleStart = Offset(
      circleCenter.dx + circleRadius * 0.7,
      circleCenter.dy + circleRadius * 0.7,
    );
    final handleEnd = Offset(size.width * 0.85, size.height * 0.85);

    canvas
      ..drawCircle(circleCenter, circleRadius, paint)
      ..drawLine(handleStart, handleEnd, paint)
      // Draw small dot in center to represent inspect point
      ..drawCircle(circleCenter, 2, fillPaint);
  }

  @override
  bool shouldRepaint(_InspectIconPainter oldDelegate) =>
      color != oldDelegate.color;
}
