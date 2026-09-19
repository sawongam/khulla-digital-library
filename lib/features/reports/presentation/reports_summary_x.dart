// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:intl/intl.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/reports/domain/models/reports_summary.dart';
import 'package:khulla/features/reports/presentation/saved_reports.dart';
import 'package:khulla/features/reports/presentation/widgets/reports_ranked_table.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

final DateFormat _monthFormat = DateFormat('MMM');

/// Maps a raw [ReportsSummary] to the formatted view models the report's
/// widgets draw — l10n and money formatting happen here, not in the
/// repository, which returns facts.
extension ReportsSummaryX on ReportsSummary {
  List<AppChartSeries> circulationSeries(AppLocalizations l10n) {
    final months = _unionMonths([
      circulationBorrowedByMonth,
      circulationReturnedByMonth,
    ]);
    AppChartPoint pointFor(List<ReportsMonthCount> counts, DateTime month) {
      final match = counts.where((c) => c.month == month);
      final value = match.isEmpty ? 0 : match.first.count;
      return AppChartPoint(
        label: _monthFormat.format(month),
        value: value.toDouble(),
      );
    }

    return [
      AppChartSeries(
        name: l10n.reportsStatBorrowed,
        points: [
          for (final month in months)
            pointFor(circulationBorrowedByMonth, month),
        ],
      ),
      AppChartSeries(
        name: l10n.reportsStatReturned,
        tone: AppStatusTone.success,
        points: [
          for (final month in months)
            pointFor(circulationReturnedByMonth, month),
        ],
      ),
    ];
  }

  List<AppChartSeries> membershipSeries(AppLocalizations l10n) => [
    AppChartSeries(
      name: l10n.reportsStatNewMembers,
      tone: AppStatusTone.info,
      points: [
        for (final entry in membershipGrowthByMonth)
          AppChartPoint(
            label: _monthFormat.format(entry.month),
            value: entry.count.toDouble(),
          ),
      ],
    ),
  ];

  List<AppChartPoint> collectionSlices() {
    const tones = [
      AppStatusTone.brand,
      AppStatusTone.info,
      AppStatusTone.success,
      AppStatusTone.warning,
      AppStatusTone.neutral,
      AppStatusTone.danger,
    ];
    return [
      for (final (index, format) in collectionByFormat.indexed)
        AppChartPoint(
          label: format.label,
          value: format.count.toDouble(),
          tone: tones[index % tones.length],
        ),
    ];
  }

  List<({String label, Money amount, AppStatusTone tone, double share})>
  fineTotals(AppLocalizations l10n) {
    final raisedMinor = finesRaised.minorUnits;
    double shareOf(Money amount) =>
        raisedMinor == 0 ? 0 : amount.minorUnits / raisedMinor;

    return [
      (
        label: l10n.reportsFinesRaised,
        amount: finesRaised,
        tone: AppStatusTone.warning,
        share: shareOf(finesRaised),
      ),
      (
        label: l10n.reportsFinesCollected,
        amount: finesCollected,
        tone: AppStatusTone.success,
        share: shareOf(finesCollected),
      ),
      (
        label: l10n.reportsFinesWaived,
        amount: finesWaived,
        tone: AppStatusTone.neutral,
        share: shareOf(finesWaived),
      ),
    ];
  }

  List<ReportsRankedRow> topTitleRows() => [
    for (final ranking in topTitles)
      (name: ranking.name, detail: ranking.detail, loans: ranking.count),
  ];

  List<ReportsRankedRow> topMemberRows() => [
    for (final ranking in topMembers)
      (name: ranking.name, detail: ranking.detail, loans: ranking.count),
  ];

  /// The header and rows a saved-report tile's CSV export writes.
  ({List<String> header, List<List<String>> rows}) csvFor(
    ReportsExportKind kind,
    AppLocalizations l10n,
  ) => switch (kind) {
    ReportsExportKind.circulation => (
      header: [
        l10n.reportsColumnMonth,
        l10n.reportsStatBorrowed,
        l10n.reportsStatReturned,
      ],
      rows: [
        for (final month in _unionMonths([
          circulationBorrowedByMonth,
          circulationReturnedByMonth,
        ]))
          [
            _monthFormat.format(month),
            '${_countFor(circulationBorrowedByMonth, month)}',
            '${_countFor(circulationReturnedByMonth, month)}',
          ],
      ],
    ),
    ReportsExportKind.collection => (
      header: [l10n.reportsColumnFormat, l10n.reportsColumnCopies],
      rows: [
        for (final format in collectionByFormat)
          [format.label, '${format.count}'],
      ],
    ),
    ReportsExportKind.members => (
      header: [l10n.reportsColumnMonth, l10n.reportsStatNewMembers],
      rows: [
        for (final entry in membershipGrowthByMonth)
          [_monthFormat.format(entry.month), '${entry.count}'],
      ],
    ),
    ReportsExportKind.fines => (
      header: [l10n.commonStatus, l10n.reportsColumnAmount],
      rows: [
        for (final total in fineTotals(l10n))
          [total.label, total.amount.display()],
      ],
    ),
    ReportsExportKind.overdue => (
      header: [
        l10n.reportsColumnTitle,
        l10n.reportsColumnMember,
        l10n.reportsColumnDueDate,
        l10n.reportsColumnDaysLate,
      ],
      rows: [
        for (final loan in overdueLoans)
          [
            loan.title,
            loan.member,
            DateFormat('d MMM y').format(loan.dueDate),
            '${loan.daysLate}',
          ],
      ],
    ),
    ReportsExportKind.acquisitions => (
      header: [l10n.reportsColumnMonth, l10n.reportsColumnCopies],
      rows: [
        for (final entry in acquisitionsByMonth)
          [_monthFormat.format(entry.month), '${entry.count}'],
      ],
    ),
  };
}

/// Every month present in any of [series], earliest first — borrowed and
/// returned queries can cover different months, so joining by index would
/// misalign counts. Missing months read as zero via [_countFor].
List<DateTime> _unionMonths(List<List<ReportsMonthCount>> series) {
  final months = <DateTime>{
    for (final list in series)
      for (final entry in list) entry.month,
  }.toList()..sort();
  return months;
}

int _countFor(List<ReportsMonthCount> counts, DateTime month) {
  for (final entry in counts) {
    if (entry.month == month) return entry.count;
  }
  return 0;
}
