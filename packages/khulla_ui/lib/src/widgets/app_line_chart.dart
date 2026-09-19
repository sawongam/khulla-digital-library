// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// A trend line with a soft fill under it - visitors per month, loans per
/// week, fines accrued.
///
/// Use it where the x-axis is time and the shape of the curve is the point.
/// Where the comparison between two named periods matters more than the
/// shape, use [AppBarChart] instead: a reader can compare two bar heights far
/// more accurately than two points on a line.
class AppLineChart extends StatelessWidget {
  const AppLineChart({
    required this.series,
    this.height = 200,
    this.showGrid = true,
    this.gridLines = 4,
    this.showDots = false,
    this.highlightIndex,
    super.key,
  }) : assert(series.length > 0, 'A chart needs at least one series');

  /// The series to draw. Two is the sensible maximum on one axis.
  final List<AppChartSeries> series;

  /// The plot's height, labels included.
  final double height;

  /// Whether to draw the horizontal grid.
  final bool showGrid;

  /// How many grid lines between the baseline and the top.
  final int gridLines;

  /// Whether to mark every measurement with a dot.
  final bool showDots;

  /// The period to mark with a vertical guide and a solid dot.
  final int? highlightIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final labels = series.first.points.map((point) => point.label).toList();

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                series: [
                  for (final one in series)
                    (
                      points: one.points,
                      color: one.tone.foreground(context),
                      fill: one.tone
                          .foreground(context)
                          .withValues(alpha: 0.12),
                    ),
                ],
                upperBound: chartUpperBound(series),
                gridColor: colors.hairline,
                gridLines: showGrid ? gridLines : 0,
                surface: scheme.surface,
                showDots: showDots,
                highlightIndex: highlightIndex,
              ),
            ),
          ),
          SizedBox(height: context.appSpacing.xs),
          Row(
            children: [
              for (final (index, label) in labels.indexed)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: index == highlightIndex
                          ? colors.textHigh
                          : colors.textMuted,
                      fontWeight: index == highlightIndex
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef _LineSeries = ({List<AppChartPoint> points, Color color, Color fill});

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.series,
    required this.upperBound,
    required this.gridColor,
    required this.gridLines,
    required this.surface,
    required this.showDots,
    required this.highlightIndex,
  });

  final List<_LineSeries> series;
  final double upperBound;
  final Color gridColor;
  final int gridLines;
  final Color surface;
  final bool showDots;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var line = 0; line <= gridLines; line++) {
      final y = size.height - (size.height / gridLines) * line;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (final one in series) {
      final count = one.points.length;
      if (count == 0) continue;
      final step = count == 1 ? size.width : size.width / (count - 1);

      final offsets = <Offset>[
        for (var index = 0; index < count; index++)
          Offset(
            step * index,
            size.height -
                size.height *
                    (one.points[index].value / upperBound).clamp(0.0, 1.0),
          ),
      ];

      final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final offset in offsets.skip(1)) {
        line.lineTo(offset.dx, offset.dy);
      }

      final area = Path.from(line)
        ..lineTo(offsets.last.dx, size.height)
        ..lineTo(offsets.first.dx, size.height)
        ..close();
      canvas
        ..drawPath(area, Paint()..color = one.fill)
        ..drawPath(
          line,
          Paint()
            ..color = one.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );

      final marked = highlightIndex;
      if (marked != null && marked >= 0 && marked < offsets.length) {
        final at = offsets[marked];
        canvas
          ..drawLine(
            Offset(at.dx, 0),
            Offset(at.dx, size.height),
            Paint()
              ..color = one.color.withValues(alpha: 0.35)
              ..strokeWidth = 1,
          )
          ..drawCircle(at, 5, Paint()..color = surface)
          ..drawCircle(
            at,
            4,
            Paint()..color = one.color,
          );
      }

      if (showDots) {
        for (final offset in offsets) {
          canvas
            ..drawCircle(offset, 3.5, Paint()..color = surface)
            ..drawCircle(
              offset,
              2.5,
              Paint()..color = one.color,
            );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.upperBound != upperBound ||
      oldDelegate.highlightIndex != highlightIndex ||
      oldDelegate.showDots != showDots ||
      oldDelegate.series != series;
}
