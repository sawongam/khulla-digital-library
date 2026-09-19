// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';

part 'dashboard_summary.freezed.dart';

/// What happened at the desk, for the dashboard's activity table.
///
/// Domain-level, unlike its presentation counterpart `DashboardActivityEntry`
/// - this names *what kind of event*, not which glyph or tone draws it.
enum DashboardActivityKind { borrow, returned, reserved, fine }

/// One row of the activity table, before it is formatted for display.
typedef DashboardActivityEvent = ({
  DashboardActivityKind kind,
  String item,
  String itemCode,
  String member,
  String memberCode,
  DateTime when,
  DateTime? due,
});

/// A count on one weekday (`0` = Sunday), for the usage chart's two series -
/// checkouts and returns, the one comparison this schema can actually answer
/// without a foot-traffic log to compare them against.
typedef DashboardWeekdayCount = ({int weekday, int count});

/// Fines raised in one calendar month, for the fines trend line.
///
/// "Raised", not "collected": a fine's `paid`/`waived` amounts carry no
/// per-payment timestamp, only a single `settledAt` once the balance clears -
/// there is no reliable month to attribute a partial payment to. What a
/// month *did* cost members is exactly what was assessed in it.
typedef DashboardMonthAmount = ({DateTime month, Money amount});

/// One slice of the catalogue by format, for the "subjects" bars - the
/// closest categorical dimension a title actually carries (see ADR 0007's
/// note that there is no separate subject/genre column).
typedef DashboardCategoryShare = ({String label, int count, double share});

/// One row of a "most borrowed" or "most active" ranking.
typedef DashboardRanking = ({String name, String detail, int count});

/// Everything the dashboard draws, for one period and the period before it -
/// the previous period is what a stat tile's trend arrow compares against.
@freezed
abstract class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required int borrowedCount,
    required int borrowedPreviousCount,
    required int returnedCount,
    required int returnedPreviousCount,
    required int overdueCount,
    required int overduePreviousCount,
    required Money finesOutstanding,
    required Money finesAssessed,
    required Money finesAssessedPrevious,
    required List<DashboardWeekdayCount> checkOutsByWeekday,
    required List<DashboardWeekdayCount> returnsByWeekday,
    required List<DashboardMonthAmount> finesByMonth,
    required Map<CopyStatus, int> collectionByStatus,
    required List<DashboardCategoryShare> categoryShares,
    required List<DashboardActivityEvent> recentActivity,
    required int holdsReadyCount,
    required int expiringMembershipsCount,
    required int damagedCopiesCount,
    required List<DashboardRanking> topTitles,
    required List<DashboardRanking> topMembers,
  }) = _DashboardSummary;
}
