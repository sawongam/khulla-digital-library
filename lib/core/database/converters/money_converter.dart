// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/money/money.dart';

/// Stores a [Money] in the minor units it already is.
///
/// The column stays a plain SQLite integer of paisa - `kMinorUnitsPerMajor` is
/// fixed at 100, and a converter that divided here would reinterpret every
/// amount already written. All this does is put the type back on the way out,
/// so the generated row class carries `Money amount` instead of `int amount`.
///
/// Declaring it on the column is what makes forgetting it impossible:
///
/// ```dart
/// class Fines extends Table {
///   IntColumn get amount => integer().map(const MoneyConverter())();
/// }
/// ```
class MoneyConverter extends TypeConverter<Money, int> {
  const MoneyConverter();

  @override
  Money fromSql(int fromDb) => Money(fromDb);

  @override
  int toSql(Money value) => value.minorUnits;
}
