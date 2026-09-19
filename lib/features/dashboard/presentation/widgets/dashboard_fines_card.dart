// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_section_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What overdue copies have cost members, month by month.
///
/// A line rather than bars: the shape of the curve is the point - a library
/// wants to see fines *falling* after it changes a loan rule, which is a
/// trend, not a set of monthly comparisons.
class DashboardFinesCard extends StatelessWidget {
  const DashboardFinesCard({
    required this.series,
    required this.latest,
    required this.trend,
    required this.trendValue,
    super.key,
  });

  /// Fines assessed, one point per month.
  final List<AppChartSeries> series;

  /// The most recent month's total, shown beside the trend pill.
  final Money latest;

  /// The change against the previous period, already formatted, or null when
  /// there is nothing to compare against.
  final String? trend;

  final num trendValue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return DashboardSectionCard(
      title: l10n.dashboardFinesTitle,
      subtitle: l10n.dashboardFinesSubtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            latest.display(),
            style: context.textTheme.titleSmall?.copyWith(
              color: context.appColors.textHigh,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trend != null) ...[
            SizedBox(width: spacing.xs),
            AppTrendPill(label: trend!, value: trendValue, inverted: true),
          ],
        ],
      ),
      child: AppLineChart(series: series, showDots: true),
    );
  }
}
