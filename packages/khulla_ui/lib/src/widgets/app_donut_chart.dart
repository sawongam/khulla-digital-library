// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// A ring showing how one total splits - collection by status, revenue by
/// source, copies by condition.
///
/// A donut, never a pie: the hole is where the total goes, and the total is
/// the figure an operator reads first. Slices are separated by a gap in the
/// surface color rather than a stroke, so the ring stays clean at any size.
///
/// Keep it to five slices or fewer. Past that the arcs are too thin to
/// compare and the answer belongs in a table.
class AppDonutChart extends StatelessWidget {
  const AppDonutChart({
    required this.slices,
    this.size = 180,
    this.thickness = 22,
    this.centerValue,
    this.centerLabel,
    this.startAngle = -1.5707963267948966, // 12 o'clock
    super.key,
  });

  /// The slices, in drawing order from the top clockwise.
  final List<AppChartPoint> slices;

  /// The ring's diameter.
  final double size;

  /// How thick the ring is.
  final double thickness;

  /// The total, already formatted, shown in the hole.
  final String? centerValue;

  /// What the total counts.
  final String? centerLabel;

  /// Where the first slice starts, in radians.
  final double startAngle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    final value = centerValue;
    final label = centerLabel;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DonutPainter(
          slices: [
            for (final slice in slices)
              (
                value: slice.value,
                color: (slice.tone ?? AppStatusTone.brand).foreground(context),
              ),
          ],
          total: total <= 0 ? 1 : total,
          empty: colors.neutralSoft,
          gap: scheme.surface,
          thickness: thickness,
          startAngle: startAngle,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: colors.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (label != null)
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _Slice = ({double value, Color color});

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.total,
    required this.empty,
    required this.gap,
    required this.thickness,
    required this.startAngle,
  });

  final List<_Slice> slices;
  final double total;
  final Color empty;
  final Color gap;
  final double thickness;
  final double startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );

    canvas.drawArc(
      rect,
      0,
      6.283185307179586,
      false,
      Paint()
        ..color = empty
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );

    var angle = startAngle;
    const gapAngle = 0.035;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = (slice.value / total) * 6.283185307179586;
      canvas.drawArc(
        rect,
        angle + gapAngle / 2,
        (sweep - gapAngle).clamp(0.0, 6.283185307179586),
        false,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.butt,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.thickness != thickness ||
      oldDelegate.slices != slices;
}
