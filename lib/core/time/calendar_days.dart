// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Calendar-day arithmetic for due dates, fines, shelf expiry and reporting
/// periods.
///
/// A library's day is a date on a wall calendar, not 24 hours on a clock.
/// Where daylight saving applies, one day a year is 23 hours long and one is
/// 25, so `Duration(days: 1)` and `difference(...).inDays` both drift by a
/// day across the change: a two-week loan issued before the clocks go back
/// came due a day early, and a fine accrued across the spring change was a
/// day short. Every helper here works on year/month/day fields instead -
/// `DateTime` normalises `day + n` across month and year ends itself - and
/// counts the gap between two dates in UTC, where no day is ever shorter
/// than another.
library;

/// Calendar date with no time-of-day, in local time.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Whole calendar days from [from] to [to]; negative when [to] is earlier.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The calendar date [days] days after [from] (before it when negative), at
/// local midnight.
DateTime addCalendarDays(DateTime from, int days) =>
    DateTime(from.year, from.month, from.day + days);
