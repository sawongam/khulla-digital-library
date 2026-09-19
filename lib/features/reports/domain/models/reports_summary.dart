// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/money/money.dart';

part 'reports_summary.freezed.dart';

/// A count in one calendar month, for a monthly trend chart.
typedef ReportsMonthCount = ({DateTime month, int count});

/// One row of a "most borrowed" or "most active" ranking, for the period.
typedef ReportsRanking = ({String name, String detail, int count});

/// One title by catalogue format, for the collection-mix donut — a snapshot,
/// not scoped to the report period.
typedef ReportsFormatCount = ({String label, int count});

/// One currently-overdue loan, for the overdue export.
typedef ReportsOverdueLoan = ({
  String title,
  String member,
  DateTime dueDate,
  int daysLate,
});

/// A title's copies acquired in one calendar month, for the acquisitions
/// export.
typedef ReportsAcquisitionMonth = ({DateTime month, int count});

/// Everything the reports screen draws for one period, and the period
/// before it for the stat tiles' trend.
@freezed
abstract class ReportsSummary with _$ReportsSummary {
  const factory ReportsSummary({
    required int borrowedCount,
    required int borrowedPreviousCount,
    required int returnedCount,
    required int returnedPreviousCount,
    required int newMembersCount,
    required int newMembersPreviousCount,
    required Money finesRaised,
    required Money finesRaisedPrevious,
    required Money finesCollected,
    required Money finesWaived,
    required List<ReportsMonthCount> circulationBorrowedByMonth,
    required List<ReportsMonthCount> circulationReturnedByMonth,
    required List<ReportsMonthCount> membershipGrowthByMonth,
    required List<ReportsFormatCount> collectionByFormat,
    required List<ReportsRanking> topTitles,
    required List<ReportsRanking> topMembers,
    required List<ReportsOverdueLoan> overdueLoans,
    required List<ReportsAcquisitionMonth> acquisitionsByMonth,
  }) = _ReportsSummary;
}
