// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/dashboard/presentation/widgets/dashboard_section_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Checkouts against returns, day by day.
///
/// Two grouped series rather than one stacked bar: the question this card
/// answers is whether the copies checked out on a given day are the ones
/// coming back, and a stacked bar hides exactly that comparison inside its
/// own total.
class DashboardUsageCard extends StatelessWidget {
  const DashboardUsageCard({required this.series, super.key});

  /// Checkouts and returns by weekday, in that order.
  final List<AppChartSeries> series;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return DashboardSectionCard(
      title: l10n.dashboardUsageTitle,
      subtitle: l10n.dashboardUsageSubtitle,
      trailing: Wrap(
        spacing: spacing.sm,
        children: [
          AppLegendDot(
            label: series.first.name,
            tone: series.first.tone,
            dense: true,
          ),
          AppLegendDot(
            label: series.last.name,
            tone: series.last.tone,
            dense: true,
          ),
        ],
      ),
      child: AppBarChart(series: series, highlightIndex: 4),
    );
  }
}
