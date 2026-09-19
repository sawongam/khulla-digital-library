// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';

/// Calendar date with no time-of-day - safe for due dates and shelf expiry.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Whole days from [from] to [to], both treated as calendar dates.
int daysBetween(DateTime from, DateTime to) =>
    dateOnly(to).difference(dateOnly(from)).inDays;

/// Adds [days] calendar days to [from].
DateTime addCalendarDays(DateTime from, int days) =>
    dateOnly(from).add(Duration(days: days));

/// Accrued overdue fine from a loan's own rule snapshot (§1.5).
///
/// No row is written while a copy is merely late; this is the amount that
/// would be assessed at return.
Money computeOverdueFine({
  required DateTime dueAt,
  required DateTime asOf,
  required Money finePerDay,
  required int graceDays,
  required Money maximumFine,
}) {
  final days = daysBetween(dueAt, asOf) - graceDays;
  if (days <= 0) return Money.zero;
  final accrued = finePerDay * days;
  return Money.min(accrued, maximumFine);
}

/// Whole days a loan is past its due date, zero when not yet overdue.
int overdueDays({
  required DateTime dueAt,
  required DateTime asOf,
}) {
  final days = daysBetween(dueAt, asOf);
  return days > 0 ? days : 0;
}
