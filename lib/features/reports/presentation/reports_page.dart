// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/files/save_csv_file.dart';
import 'package:khulla/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:khulla/features/reports/presentation/cubit/reports_state.dart';
import 'package:khulla/features/reports/presentation/reports_summary_x.dart';
import 'package:khulla/features/reports/presentation/saved_reports.dart';
import 'package:khulla/features/reports/presentation/widgets/reports_board_cards.dart';
import 'package:khulla/features/reports/presentation/widgets/reports_fines_card.dart';
import 'package:khulla/features/reports/presentation/widgets/reports_header.dart';
import 'package:khulla/features/reports/presentation/widgets/reports_stat_strip.dart';
import 'package:khulla/features/reports/presentation/widgets/saved_report_tile.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/navigation_group.dart';
import 'package:khulla/shared/models/load_status.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What the library did over a period, and what it holds today.
///
/// The screen answers two different audiences with one layout: the top half
/// is for the librarian deciding what to buy and who to chase, the saved
/// reports at the bottom are for the committee that wants a CSV. Both read
/// the same figures, which is the only way the two ever agree.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: AppSpinner());
        }
        if (state.status.hasError) {
          final l10n = context.l10n;
          return AppErrorView(
            message: state.error?.localizedMessage(l10n) ?? '',
            retryLabel: l10n.commonRetry,
            onRetry: () => context.read<ReportsCubit>().load(),
          );
        }
        return _ReportsBoard(state: state);
      },
    );
  }
}

/// The window of time a report covers.
enum ReportPeriod { month, quarter, year }

class _ReportsBoard extends StatelessWidget {
  const _ReportsBoard({required this.state});

  final ReportsState state;

  Future<void> _export(
    BuildContext context,
    ReportsExportKind kind,
    String title,
  ) async {
    final l10n = context.l10n;
    final csv = state.summary!.csvFor(kind, l10n);
    try {
      final saved = await saveCsvFile(
        filename: '${title.toLowerCase().replaceAll(' ', '-')}.csv',
        header: csv.header,
        rows: csv.rows,
      );
      if (saved == null || !context.mounted) return;
      AppToast.success(
        context,
        message: l10n.reportsExportedToast(title),
        description: saved.path,
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final sideBySide = context.formFactor.isAtLeast(FormFactor.expanded);
    final summary = state.summary!;
    final collection = summary.collectionSlices();
    final collectionTotal = collection.fold<double>(
      0,
      (sum, slice) => sum + slice.value,
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
                ReportsHeader(period: state.period),
                SizedBox(height: spacing.lg),
                ReportsStatStrip(summary: summary),
                SizedBox(height: spacing.lg),
                ReportsCirculationCard(summary: summary),
                SizedBox(height: spacing.md),
                if (sideBySide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ReportsMembershipCard(summary: summary),
                        ),
                        SizedBox(width: spacing.md),
                        Expanded(
                          child: ReportsCollectionMixCard(
                            slices: collection,
                            total: collectionTotal,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ReportsMembershipCard(summary: summary),
                  SizedBox(height: spacing.md),
                  ReportsCollectionMixCard(
                    slices: collection,
                    total: collectionTotal,
                  ),
                ],
                SizedBox(height: spacing.md),
                ReportsFinesCard(totals: summary.fineTotals(l10n)),
                SizedBox(height: spacing.md),
                ReportsRankedSection(
                  summary: summary,
                  sideBySide: sideBySide,
                ),
                SizedBox(height: spacing.lg),
                AppSectionHeader(
                  title: l10n.reportsSavedTitle,
                  subtitle: l10n.reportsSavedSubtitle,
                ),
                SizedBox(height: spacing.md),
                NavigationGroup(
                  children: [
                    for (final report in reportsSaved(l10n))
                      SavedReportTile(
                        report: report,
                        onExport: () => unawaited(
                          _export(context, report.kind, report.title),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
