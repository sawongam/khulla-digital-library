// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// One measurement in a chart: what it is, and how much of it there was.
///
/// Charts here take *tones*, not colors. A series that means "overdue" is
/// [AppStatusTone.danger] in a bar chart, in a donut and on a badge, and the
/// theme decides what danger looks like in light and in dark. A caller that
/// could pass a `Color` would eventually pass one that fails contrast on one
/// of the two.
class AppChartPoint {
  const AppChartPoint({
    required this.label,
    required this.value,
    this.tone,
  });

  /// The x-axis label - a month, a weekday, a category.
  final String label;

  /// The measurement. Never negative in this product: every figure a library
  /// charts is a count or an amount.
  final double value;

  /// Overrides the series tone for this point alone - the highlighted bar,
  /// the slice being explained.
  final AppStatusTone? tone;
}

/// A named run of points sharing one tone.
class AppChartSeries {
  const AppChartSeries({
    required this.name,
    required this.points,
    this.tone = AppStatusTone.brand,
  });

  /// The series' name, as the legend shows it.
  final String name;

  /// The points, in x order.
  final List<AppChartPoint> points;

  /// The tone every point takes unless it overrides it.
  final AppStatusTone tone;

  /// The largest value in the series, or zero when it is empty.
  double get maxValue => points.isEmpty
      ? 0
      : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
}

/// The largest value across [series], with a floor of 1 so an all-zero chart
/// still lays out instead of dividing by nothing.
double chartUpperBound(List<AppChartSeries> series) {
  final max = series.fold<double>(
    0,
    (acc, s) => s.maxValue > acc ? s.maxValue : acc,
  );
  return max <= 0 ? 1 : max;
}
