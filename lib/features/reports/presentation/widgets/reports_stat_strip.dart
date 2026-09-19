// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/reports/domain/models/reports_summary.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The four headline figures: borrowed, returned, new members, fines raised.
///
/// Every tile carries its trend against the previous window and the same
/// "last month" caption. Fines invert the trend - up is bad there.
class ReportsStatStrip extends StatelessWidget {
  const ReportsStatStrip({required this.summary, super.key});

  final ReportsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppStatStrip(
      tiles: [
        AppStatTile(
          label: l10n.reportsStatBorrowed,
          value: '${summary.borrowedCount}',
          icon: AppIcons.checkOut,
          tone: AppStatusTone.brand,
          trend: _trendText(
            summary.borrowedCount,
            summary.borrowedPreviousCount,
          ),
          trendValue: _trendValue(
            summary.borrowedCount,
            summary.borrowedPreviousCount,
          ),
          caption: l10n.commonLastMonth,
        ),
        AppStatTile(
          label: l10n.reportsStatReturned,
          value: '${summary.returnedCount}',
          icon: AppIcons.returned,
          tone: AppStatusTone.success,
          trend: _trendText(
            summary.returnedCount,
            summary.returnedPreviousCount,
          ),
          trendValue: _trendValue(
            summary.returnedCount,
            summary.returnedPreviousCount,
          ),
          caption: l10n.commonLastMonth,
        ),
        AppStatTile(
          label: l10n.reportsStatNewMembers,
          value: '${summary.newMembersCount}',
          icon: AppIcons.addPerson,
          tone: AppStatusTone.info,
          trend: _trendText(
            summary.newMembersCount,
            summary.newMembersPreviousCount,
          ),
          trendValue: _trendValue(
            summary.newMembersCount,
            summary.newMembersPreviousCount,
          ),
          caption: l10n.commonLastMonth,
        ),
        AppStatTile(
          label: l10n.reportsStatFines,
          value: summary.finesRaised.display(),
          icon: AppIcons.payment,
          tone: AppStatusTone.warning,
          trend: _trendText(
            summary.finesRaised.minorUnits,
            summary.finesRaisedPrevious.minorUnits,
          ),
          trendValue: _trendValue(
            summary.finesRaised.minorUnits,
            summary.finesRaisedPrevious.minorUnits,
          ),
          trendInverted: true,
          caption: l10n.commonLastMonth,
        ),
      ],
    );
  }
}

String? _trendText(int current, int previous) {
  if (previous == 0) return current == 0 ? null : '+100%';
  final change = ((current - previous) / previous) * 100;
  final sign = change >= 0 ? '+' : '';
  return '$sign${change.toStringAsFixed(1)}%';
}

num _trendValue(int current, int previous) {
  if (previous == 0) return current == 0 ? 0 : 100;
  return ((current - previous) / previous) * 100;
}
