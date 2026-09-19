// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/reports/domain/models/reports_summary.dart';
import 'package:khulla/features/reports/presentation/reports_summary_x.dart';
import 'package:khulla/features/reports/presentation/widgets/reports_ranked_table.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Borrowed vs returned over the window, as a bar chart with its legend.
class ReportsCirculationCard extends StatelessWidget {
  const ReportsCirculationCard({required this.summary, super.key});

  final ReportsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return SectionCard(
      title: l10n.reportsCirculationTitle,
      subtitle: l10n.reportsCirculationSubtitle,
      trailing: Wrap(
        spacing: spacing.sm,
        children: [
          AppLegendDot(
            label: l10n.reportsStatBorrowed,
            tone: AppStatusTone.brand,
            dense: true,
          ),
          AppLegendDot(
            label: l10n.reportsStatReturned,
            tone: AppStatusTone.success,
            dense: true,
          ),
        ],
      ),
      child: AppBarChart(
        series: summary.circulationSeries(l10n),
        height: 240,
      ),
    );
  }
}

/// New members over the window, as a line chart.
class ReportsMembershipCard extends StatelessWidget {
  const ReportsMembershipCard({required this.summary, super.key});

  final ReportsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.reportsMembersTitle,
      subtitle: l10n.reportsMembersSubtitle,
      child: AppLineChart(
        series: summary.membershipSeries(l10n),
        showDots: true,
      ),
    );
  }
}

/// Every catalogued copy by format, as a donut and its legend.
class ReportsCollectionMixCard extends StatelessWidget {
  const ReportsCollectionMixCard({
    required this.slices,
    required this.total,
    super.key,
  });

  final List<AppChartPoint> slices;
  final double total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return SectionCard(
      title: l10n.reportsCollectionTitle,
      subtitle: l10n.reportsCollectionSubtitle,
      child: Row(
        children: [
          AppDonutChart(
            slices: slices,
            size: 150,
            thickness: 20,
            centerValue: total.toStringAsFixed(0),
            centerLabel: l10n.dashboardCollectionTotal,
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final slice in slices)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.xs),
                    child: AppLegendDot(
                      label: slice.label,
                      tone: slice.tone ?? AppStatusTone.brand,
                      value: slice.value.toStringAsFixed(0),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Top titles beside top members, side by side on wide windows and stacked
/// on narrow ones.
class ReportsRankedSection extends StatelessWidget {
  const ReportsRankedSection({
    required this.summary,
    required this.sideBySide,
    super.key,
  });

  final ReportsSummary summary;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    final ranked = [
      SectionCard(
        title: l10n.reportsTopTitlesTitle,
        subtitle: l10n.reportsTopTitlesSubtitle,
        child: ReportsRankedTable(
          rows: summary.topTitleRows(),
          nameLabel: l10n.reportsColumnTitle,
        ),
      ),
      SectionCard(
        title: l10n.reportsTopMembersTitle,
        subtitle: l10n.reportsTopMembersSubtitle,
        child: ReportsRankedTable(
          rows: summary.topMemberRows(),
          nameLabel: l10n.reportsColumnMember,
        ),
      ),
    ];

    if (sideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ranked.first),
          SizedBox(width: spacing.md),
          Expanded(child: ranked.last),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ranked.first,
        SizedBox(height: spacing.md),
        ranked.last,
      ],
    );
  }
}
