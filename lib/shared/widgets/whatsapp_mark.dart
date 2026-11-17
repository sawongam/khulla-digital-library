// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/widgets.dart';

/// A small WhatsApp glyph: a speech bubble with a handset inside.
///
/// The icon set has no brand marks, so this is drawn by hand in one colour,
/// which keeps it on the theme like every other icon.
class WhatsappMark extends StatelessWidget {
  const WhatsappMark({required this.size, required this.color, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _WhatsappPainter(color),
      ),
    );
  }
}

class _WhatsappPainter extends CustomPainter {
  const _WhatsappPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 24;

    // Bubble: a circle with a tail at the lower left.
    final bubble = Path()
      ..moveTo(2.5 * u, 21.5 * u)
      ..lineTo(4.21 * u, 16.5 * u)
      ..arcToPoint(
        Offset(8.92 * u, 20.46 * u),
        radius: Radius.circular(9 * u),
        largeArc: true,
      )
      ..close();
    canvas
      ..drawPath(
        bubble,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7 * u
          ..strokeJoin = StrokeJoin.round,
      )
      // Handset, drawn in a 24-unit box and shrunk into the bubble.
      ..save()
      ..translate(12 * u, 12 * u)
      ..scale(0.5 * u)
      ..translate(-12, -12)
      ..drawPath(_handset(), Paint()..color = color)
      ..restore();
  }

  Path _handset() {
    return Path()
      ..moveTo(6.62, 10.79)
      ..relativeCubicTo(1.44, 2.83, 3.76, 5.14, 6.59, 6.59)
      ..relativeLineTo(2.2, -2.2)
      ..relativeCubicTo(0.27, -0.27, 0.67, -0.36, 1.02, -0.24)
      ..relativeCubicTo(1.12, 0.37, 2.33, 0.57, 3.57, 0.57)
      ..relativeCubicTo(0.55, 0, 1, 0.45, 1, 1)
      ..lineTo(21, 20)
      ..relativeCubicTo(0, 0.55, -0.45, 1, -1, 1)
      ..relativeCubicTo(-9.39, 0, -17, -7.61, -17, -17)
      ..relativeCubicTo(0, -0.55, 0.45, -1, 1, -1)
      ..relativeLineTo(3.5, 0)
      ..relativeCubicTo(0.55, 0, 1, 0.45, 1, 1)
      ..relativeCubicTo(0, 1.25, 0.2, 2.45, 0.57, 3.57)
      ..relativeCubicTo(0.11, 0.35, 0.03, 0.74, -0.25, 1.02)
      ..relativeLineTo(-2.2, 2.2)
      ..close();
  }

  @override
  bool shouldRepaint(_WhatsappPainter old) => old.color != color;
}
