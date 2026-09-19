// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:intl/intl.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/features/dashboard/domain/models/dashboard_summary.dart'
    hide DashboardActivityKind;
import 'package:khulla/features/dashboard/domain/models/dashboard_summary.dart'
    as domain
    show DashboardActivityKind;
import 'package:khulla/features/dashboard/presentation/models/dashboard_activity_entry.dart';
import 'package:khulla/features/dashboard/presentation/models/dashboard_attention_item.dart';
import 'package:khulla/features/dashboard/presentation/models/dashboard_ranked_entry.dart';
import 'package:khulla/features/dashboard/presentation/models/dashboard_stat.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

const List<String> _weekdayLabels = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

final DateFormat _activityWhenFormat = DateFormat('d MMM, h:mm a');
final DateFormat _dueFormat = DateFormat('d MMM');
final DateFormat _monthFormat = DateFormat('MMM');

/// Maps a raw [DashboardSummary] to the formatted view models the board's
/// widgets already draw — the same shapes `dashboard_placeholder.dart` used
/// to hand-write, computed for real and localized here rather than in the
/// repository, which returns facts, not display strings.
extension DashboardSummaryX on DashboardSummary {
  List<DashboardStat> stats(AppLocalizations l10n, DashboardPeriod period) {
    final caption = switch (period) {
      DashboardPeriod.today => l10n.commonYesterday,
      DashboardPeriod.week => l10n.commonLastWeek,
      DashboardPeriod.month => l10n.commonLastMonth,
    };

    return [
      DashboardStat(
        label: l10n.dashboardStatBorrowed,
        route: Routes.circulation,
        value: '$borrowedCount',
        icon: AppIcons.checkOut,
        tone: AppStatusTone.brand,
        caption: caption,
        trend: _trendText(borrowedCount, borrowedPreviousCount),
        trendValue: _trendValueOrZero(borrowedCount, borrowedPreviousCount),
      ),
      DashboardStat(
        label: l10n.dashboardStatReturned,
        route: Routes.circulationReturn,
        value: '$returnedCount',
        icon: AppIcons.returned,
        tone: AppStatusTone.success,
        caption: caption,
        trend: _trendText(returnedCount, returnedPreviousCount),
        trendValue: _trendValueOrZero(returnedCount, returnedPreviousCount),
      ),
      DashboardStat(
        label: l10n.dashboardStatOverdue,
        route: Routes.circulation,
        value: '$overdueCount',
        icon: AppIcons.error,
        tone: AppStatusTone.danger,
        caption: caption,
        trend: _trendText(overdueCount, overduePreviousCount),
        trendValue: _trendValueOrZero(overdueCount, overduePreviousCount),
        trendInverted: true,
      ),
      DashboardStat(
        label: l10n.dashboardStatFines,
        route: Routes.circulationFines,
        value: finesOutstanding.display(),
        icon: AppIcons.wallet,
        tone: AppStatusTone.warning,
        caption: caption,
        trend: _trendText(
          finesAssessed.minorUnits,
          finesAssessedPrevious.minorUnits,
        ),
        trendValue: _trendValueOrZero(
          finesAssessed.minorUnits,
          finesAssessedPrevious.minorUnits,
        ),
        trendInverted: true,
      ),
    ];
  }

  List<AppChartSeries> usageSeries(AppLocalizations l10n) {
    AppChartPoint pointFor(List<DashboardWeekdayCount> counts, int weekday) {
      final match = counts.where((c) => c.weekday == weekday);
      final value = match.isEmpty ? 0 : match.first.count;
      return AppChartPoint(
        label: _weekdayLabels[weekday],
        value: value.toDouble(),
      );
    }

    return [
      AppChartSeries(
        name: l10n.dashboardUsageLoans,
        points: [
          for (var weekday = 0; weekday < 7; weekday++)
            pointFor(checkOutsByWeekday, weekday),
        ],
      ),
      AppChartSeries(
        name: l10n.dashboardUsageReturns,
        tone: AppStatusTone.success,
        points: [
          for (var weekday = 0; weekday < 7; weekday++)
            pointFor(returnsByWeekday, weekday),
        ],
      ),
    ];
  }

  List<AppChartSeries> finesSeries(AppLocalizations l10n) => [
    AppChartSeries(
      name: l10n.dashboardFinesTitle,
      tone: AppStatusTone.warning,
      points: [
        for (final month in finesByMonth)
          AppChartPoint(
            label: _monthFormat.format(month.month),
            value: month.amount.minorUnits / Money.major(1).minorUnits,
          ),
      ],
    ),
  ];

  /// The change in fines assessed against the previous period, already
  /// formatted, or null when there is nothing to compare against.
  String? get finesTrendText =>
      _trendText(finesAssessed.minorUnits, finesAssessedPrevious.minorUnits);

  num get finesTrendValue => _trendValueOrZero(
    finesAssessed.minorUnits,
    finesAssessedPrevious.minorUnits,
  );

  List<AppChartPoint> collectionSlices(AppLocalizations l10n) => [
    for (final status in CopyStatus.values)
      if ((collectionByStatus[status] ?? 0) > 0)
        AppChartPoint(
          label: status.label(l10n),
          value: (collectionByStatus[status] ?? 0).toDouble(),
          tone: status.tone,
        ),
  ];

  List<({String label, String count, double share})> subjectShares() => [
    for (final share in categoryShares)
      (label: share.label, count: '${share.count}', share: share.share),
  ];

  List<DashboardActivityEntry> activity(AppLocalizations l10n) => [
    for (final event in recentActivity)
      DashboardActivityEntry(
        kind: switch (event.kind) {
          domain.DashboardActivityKind.borrow => DashboardActivityKind.borrow,
          domain.DashboardActivityKind.returned =>
            DashboardActivityKind.returned,
          domain.DashboardActivityKind.reserved =>
            DashboardActivityKind.reserved,
          domain.DashboardActivityKind.fine => DashboardActivityKind.fine,
        },
        item: event.item,
        itemCode: event.itemCode,
        member: event.member,
        memberCode: event.memberCode,
        when: _activityWhenFormat.format(event.when),
        due: event.due == null ? null : _dueFormat.format(event.due!),
        tone: switch (event.kind) {
          domain.DashboardActivityKind.borrow => AppStatusTone.brand,
          domain.DashboardActivityKind.returned => AppStatusTone.success,
          domain.DashboardActivityKind.reserved => AppStatusTone.info,
          domain.DashboardActivityKind.fine => AppStatusTone.danger,
        },
      ),
  ];

  List<DashboardAttentionItem> attentionItems(AppLocalizations l10n) => [
    if (overdueCount > 0)
      DashboardAttentionItem(
        label: l10n.dashboardAttentionOverdue,
        count: '$overdueCount',
        icon: AppIcons.error,
        tone: AppStatusTone.danger,
        route: Routes.circulation,
      ),
    if (holdsReadyCount > 0)
      DashboardAttentionItem(
        label: l10n.dashboardAttentionHolds,
        count: '$holdsReadyCount',
        icon: AppIcons.bookmark,
        tone: AppStatusTone.info,
        route: Routes.circulationReservations,
      ),
    if (expiringMembershipsCount > 0)
      DashboardAttentionItem(
        label: l10n.dashboardAttentionExpiring,
        count: '$expiringMembershipsCount',
        icon: AppIcons.clock,
        tone: AppStatusTone.warning,
        route: Routes.members,
      ),
    if (damagedCopiesCount > 0)
      DashboardAttentionItem(
        label: l10n.dashboardAttentionDamaged,
        count: '$damagedCopiesCount',
        icon: AppIcons.damage,
        tone: AppStatusTone.neutral,
        route: Routes.catalogCopies,
      ),
  ];

  List<DashboardRankedEntry> topTitleEntries(AppLocalizations l10n) => [
    for (final ranking in topTitles)
      DashboardRankedEntry(
        name: ranking.name,
        detail: ranking.detail,
        figure: l10n.dashboardBorrowCount('${ranking.count}'),
      ),
  ];

  List<DashboardRankedEntry> topMemberEntries(AppLocalizations l10n) => [
    for (final ranking in topMembers)
      DashboardRankedEntry(
        name: ranking.name,
        detail: ranking.detail,
        figure: l10n.dashboardBorrowCount('${ranking.count}'),
      ),
  ];
}

String? _trendText(int current, int previous) {
  final value = _trendValue(current, previous);
  if (value == null) return null;
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(1)}%';
}

double? _trendValue(int current, int previous) {
  if (previous == 0) return current == 0 ? null : 100;
  return ((current - previous) / previous) * 100;
}

/// [DashboardStat.trendValue] is non-nullable — zero when there is nothing
/// to compare, which reads as "flat", not as a rise or a fall.
num _trendValueOrZero(int current, int previous) =>
    _trendValue(current, previous) ?? 0;
