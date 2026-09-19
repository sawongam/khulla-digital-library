// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';

/// Stores a calendar date without a time-of-day.
///
/// Drift writes instants as UTC ISO-8601 strings. A due date written at 22:00
/// in UTC+05:45 round-trips as the previous day - this converter keeps genuine
/// dates as `YYYY-MM-DD`, which sorts correctly as text and never shifts a day.
class DateOnlyConverter extends TypeConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb);

  @override
  String toSql(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
