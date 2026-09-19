// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/converters/money_converter.dart';

/// Editable member categories - student, teacher, public, and so on.
///
/// Each nullable rule column overrides the global loan-rules singleton when
/// set; `NULL` means inherit. Seeded rows start with every override null so
/// the library-wide defaults apply until the operator deliberately changes one.
@DataClassName('MemberTypeRow')
class MemberTypes extends Table {
  TextColumn get id => text()();

  /// Stable machine id on seeded rows only.
  TextColumn get code => text().nullable().unique()();

  TextColumn get name => text().withLength(min: 1, max: 60)();

  IntColumn get sortOrder => integer()();

  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  IntColumn get loanPeriodDays => integer().nullable()();

  IntColumn get borrowingLimit => integer().nullable()();

  IntColumn get renewalLimit => integer().nullable()();

  IntColumn get renewalPeriodDays => integer().nullable()();

  IntColumn get finePerDay =>
      integer().map(const MoneyConverter()).nullable()();

  IntColumn get graceDays => integer().nullable()();

  IntColumn get maximumFinePerCopy =>
      integer().map(const MoneyConverter()).nullable()();

  IntColumn get maxOutstandingFine =>
      integer().map(const MoneyConverter()).nullable()();

  IntColumn get membershipDurationMonths => integer().nullable()();

  IntColumn get reservationLimit => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
