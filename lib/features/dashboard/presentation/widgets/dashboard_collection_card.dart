// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/dashboard/presentation/widgets/dashboard_section_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Where every copy in the collection is right now.
///
/// The donut carries the total in its hole because that is the figure an
/// operator reads first - "how many copies do we have" - and the slices
/// answer the follow-up without a second card.
class DashboardCollectionCard extends StatelessWidget {
  const DashboardCollectionCard({required this.slices, super.key});

  /// One slice per copy status that has at least one copy.
  final List<AppChartPoint> slices;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final total = slices.fold<double>(
      0,
      (sum, slice) => sum + slice.value,
    );

    return DashboardSectionCard(
      title: l10n.dashboardCollectionTitle,
      subtitle: l10n.dashboardCollectionSubtitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final legend = Column(
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
          );

          final chart = AppDonutChart(
            slices: slices,
            centerValue: total.toStringAsFixed(0),
            centerLabel: l10n.dashboardCollectionTotal,
          );

          if (constraints.maxWidth < 360) {
            return Column(
              children: [
                Center(child: chart),
                SizedBox(height: spacing.md),
                legend,
              ],
            );
          }

          return Row(
            children: [
              chart,
              SizedBox(width: spacing.md),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}
