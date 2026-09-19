// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/converters/money_converter.dart';
import 'package:khulla/core/money/money.dart';

/// The library-wide lending policy — one row, for the whole file.
///
/// Member types may override individual columns; `NULL` there means inherit
/// from here. Global-only knobs (`holdShelfDays`, overdue blocking, auto-renew)
/// live only on this row.
@DataClassName('LoanRulesRow')
class LoanRules extends Table {
  /// Always 1. See [customConstraints].
  IntColumn get id => integer().withDefault(const Constant(1))();

  IntColumn get loanPeriodDays => integer().withDefault(const Constant(14))();

  IntColumn get borrowingLimit => integer().withDefault(const Constant(5))();

  IntColumn get renewalLimit => integer().withDefault(const Constant(2))();

  IntColumn get renewalPeriodDays => integer().nullable()();

  IntColumn get finePerDay => integer()
      .map(const MoneyConverter())
      .withDefault(Constant(Money.major(5).minorUnits))();

  IntColumn get graceDays => integer().withDefault(const Constant(1))();

  IntColumn get maximumFinePerCopy => integer()
      .map(const MoneyConverter())
      .withDefault(Constant(Money.major(500).minorUnits))();

  IntColumn get maxOutstandingFine =>
      integer().map(const MoneyConverter()).nullable()();

  IntColumn get membershipDurationMonths =>
      integer().withDefault(const Constant(12))();

  IntColumn get reservationLimit => integer().withDefault(const Constant(3))();

  IntColumn get holdShelfDays => integer().withDefault(const Constant(7))();

  BoolColumn get blockOverdueBorrowers =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get autoRenewWhenUnreserved =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();

  static const int singletonId = 1;

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const ['CHECK (id = 1)'];
}
