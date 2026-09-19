// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// One figure on the dashboard, ready for [AppStatTile].
///
/// [value] is already a string because the three kinds of figure the board
/// shows - a count, a date-bound count and a money total - format differently,
/// and only the caller knows which is which. A `Money` total arrives here as
/// `amount.display()`, never as a number.
class DashboardStat {
  const DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.tone = AppStatusTone.neutral,
    this.route,
    this.trend,
    this.trendValue = 0,
    this.trendInverted = false,
  });

  /// What is being counted, already localized.
  final String label;

  /// The figure, already formatted.
  final String value;

  /// Glyph in the tile's badge.
  final AppIconSpec icon;

  /// A line of context under the figure.
  final String? caption;

  /// Which semantic family the tile draws from.
  final AppStatusTone tone;

  /// Where tapping the tile leads, when the list behind it exists. Null while
  /// the section is still a placeholder.
  final String? route;

  /// The change against the previous period, already formatted (`+8.2%`).
  final String? trend;

  /// The change's sign. Only the sign is read; the text is [trend].
  final num trendValue;

  /// Whether a fall is the good news - overdue copies, fines outstanding.
  final bool trendInverted;
}
