// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:khulla/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:khulla/features/dashboard/presentation/dashboard_summary_x.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_activity_section.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_attention_section.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_collection_card.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_fines_card.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_ranked_card.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_stats_strip.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_subjects_card.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_usage_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/models/load_status.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The shell's landing tab: what the library looks like right now.
///
/// It is the app's densest page, and the only one laid out as two panes: the
/// left column is *what happened* - the figures, the charts, the desk's
/// activity - and the right rail is *what is still owed*, the worklist a
/// shift is judged by. Below `large` the rail folds under the column rather
/// than squeezing beside it, because a 300px chart is worse than no chart.
///
/// Surface is used as hierarchy rather than as decoration. The figures share
/// one bordered strip; the three charts keep a card each, because a plot
/// needs a bounded drawing area to be read against; and the lists - the
/// worklist, the two rankings, the subject bars - sit on the page canvas
/// under their headings, since a list already has an edge and a border round
/// it only adds another rectangle.
///
/// The board is a single [CustomScrollView], so the page scrolls as one
/// surface and no section nests a scrollable inside another - the rule that
/// keeps a ten-thousand-title catalogue openable applies here too.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: AppSpinner());
        }
        if (state.status.hasError) {
          final l10n = context.l10n;
          return AppErrorView(
            message: state.error?.localizedMessage(l10n) ?? '',
            retryLabel: l10n.commonRetry,
            onRetry: () => context.read<DashboardCubit>().load(),
          );
        }
        return _DashboardBoard(state: state);
      },
    );
  }
}

class _DashboardBoard extends StatelessWidget {
  const _DashboardBoard({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final formFactor = context.formFactor;
    final twoPane = formFactor.usesExtendedRail;
    final sideBySide = formFactor.isAtLeast(FormFactor.expanded);
    final summary = state.summary!;
    final finesSeries = summary.finesSeries(l10n);
    final latestFines = summary.finesByMonth.isEmpty
        ? Money.zero
        : summary.finesByMonth.last.amount;

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardUsageCard(series: summary.usageSeries(l10n)),
        SizedBox(height: spacing.md),
        if (sideBySide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: DashboardFinesCard(
                  series: finesSeries,
                  latest: latestFines,
                  trend: summary.finesTrendText,
                  trendValue: summary.finesTrendValue,
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                flex: 2,
                child: DashboardCollectionCard(
                  slices: summary.collectionSlices(l10n),
                ),
              ),
            ],
          )
        else ...[
          DashboardFinesCard(
            series: finesSeries,
            latest: latestFines,
            trend: summary.finesTrendText,
            trendValue: summary.finesTrendValue,
          ),
          SizedBox(height: spacing.md),
          DashboardCollectionCard(slices: summary.collectionSlices(l10n)),
        ],
        SizedBox(height: spacing.md),
        DashboardActivitySection(entries: summary.activity(l10n)),
      ],
    );

    final sideColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardAttentionSection(items: summary.attentionItems(l10n)),
        SizedBox(height: spacing.lg),
        DashboardRankedCard(
          title: l10n.dashboardTopTitlesTitle,
          subtitle: l10n.commonThisMonth,
          entries: summary.topTitleEntries(l10n),
        ),
        SizedBox(height: spacing.lg),
        DashboardRankedCard(
          title: l10n.dashboardTopMembersTitle,
          subtitle: l10n.commonThisMonth,
          entries: summary.topMemberEntries(l10n),
        ),
        SizedBox(height: spacing.lg),
        DashboardSubjectsCard(subjects: summary.subjectShares()),
      ],
    );

    return AppPageBody(
      wide: true,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              spacing.page,
              spacing.lg,
              spacing.page,
              spacing.xlg,
            ),
            sliver: SliverList.list(
              children: [
                DashboardHeader(
                  period: state.period,
                  onPeriodChanged: (period) =>
                      context.read<DashboardCubit>().changePeriod(period),
                ),
                SizedBox(height: spacing.md),
                DashboardStatsStrip(stats: summary.stats(l10n, state.period)),
                SizedBox(height: spacing.lg),
                if (twoPane)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: mainColumn),
                      SizedBox(width: spacing.lg),
                      SizedBox(width: 320, child: sideColumn),
                    ],
                  )
                else ...[
                  mainColumn,
                  SizedBox(height: spacing.lg),
                  sideColumn,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
