// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// A column chart for a bounded run of periods - a week of check-ins, eight
/// months of revenue, six categories of stock.
///
/// Painted rather than pulled from a charting package: everything this
/// product charts is a dozen bars with a baseline and a label under each, and
/// a dependency that ships pan, zoom, tooltips and its own theme costs more
/// to keep matching the design system than the painter costs to own.
///
/// Multiple series are grouped side by side per period, not stacked - a
/// stacked bar answers "how much in total" and every question this app asks
/// is "how do these two compare".
class AppBarChart extends StatelessWidget {
  const AppBarChart({
    required this.series,
    this.height = 200,
    this.showGrid = true,
    this.gridLines = 4,
    this.maxValueLabel,
    this.highlightIndex,
    super.key,
  }) : assert(series.length > 0, 'A chart needs at least one series');

  /// The series to draw, in legend order.
  final List<AppChartSeries> series;

  /// The plot's height, labels included.
  final double height;

  /// Whether to draw the horizontal grid behind the bars.
  final bool showGrid;

  /// How many grid lines to draw between the baseline and the top.
  final int gridLines;

  /// The value at the top of the axis, already formatted. Null hides the
  /// axis labels entirely, which is the right call inside a small tile.
  final String? maxValueLabel;

  /// The period to emphasise - today, the month being explained. Every other
  /// bar is dimmed rather than the highlight being brightened, so the chart
  /// keeps one accent instead of gaining a second.
  final int? highlightIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final labels = series.first.points.map((point) => point.label).toList();

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(
                series: [
                  for (final one in series)
                    (
                      points: one.points,
                      color: one.tone.foreground(context),
                      soft: one.tone.background(context),
                    ),
                ],
                upperBound: chartUpperBound(series),
                gridColor: colors.hairline,
                gridLines: showGrid ? gridLines : 0,
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

typedef _BarSeries = ({List<AppChartPoint> points, Color color, Color soft});

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.series,
    required this.upperBound,
    required this.gridColor,
    required this.gridLines,
    required this.highlightIndex,
  });

  final List<_BarSeries> series;
  final double upperBound;
  final Color gridColor;
  final int gridLines;
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

    final columns = series.first.points.length;
    if (columns == 0) return;

    final slot = size.width / columns;
    final barCount = series.length;
    // A group fills 56% of its slot, so bars breathe and the eye can group
    // them without a divider.
    final groupWidth = slot * 0.56;
    final barWidth = groupWidth / barCount;
    final radius = Radius.circular(barWidth < 8 ? barWidth / 2 : 4);

    for (var column = 0; column < columns; column++) {
      final dimmed = highlightIndex != null && highlightIndex != column;
      final left = slot * column + (slot - groupWidth) / 2;

      for (var index = 0; index < barCount; index++) {
        final one = series[index];
        if (column >= one.points.length) continue;
        final point = one.points[column];
        final ratio = (point.value / upperBound).clamp(0.0, 1.0);
        final barHeight = size.height * ratio;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            left + barWidth * index,
            size.height - barHeight,
            barWidth - 2,
            barHeight,
          ),
          topLeft: radius,
          topRight: radius,
        );
        canvas.drawRRect(
          rect,
          Paint()..color = dimmed ? one.soft : one.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.upperBound != upperBound ||
      oldDelegate.highlightIndex != highlightIndex ||
      oldDelegate.gridLines != gridLines ||
      oldDelegate.series != series;
}
