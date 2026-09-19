// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/converters/date_only_converter.dart';
import 'package:khulla/core/database/converters/money_converter.dart';
import 'package:khulla/features/catalog/copy/data/tables/copies.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/members/data/tables/members.dart';
import 'package:khulla/features/users/data/tables/staff.dart';

/// One checkout - open while [returnedAt] is null.
@DataClassName('LoanRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX loans_one_open_per_copy ON loans (copy_id) WHERE returned_at IS NULL',
)
// `due_at` makes the member list's open and overdue counts index-only.
@TableIndex.sql(
  'CREATE INDEX loans_open_by_member ON loans (member_id, due_at) WHERE returned_at IS NULL',
)
@TableIndex.sql(
  'CREATE INDEX loans_due ON loans (due_at) WHERE returned_at IS NULL',
)
@TableIndex.sql(
  'CREATE INDEX loans_member_history ON loans (member_id, checked_out_at DESC)',
)
@TableIndex.sql(
  'CREATE INDEX loans_copy_history ON loans (copy_id, checked_out_at DESC)',
)
// Date-range reads on the dashboard and reports, and recent activity.
@TableIndex.sql('CREATE INDEX loans_checked_out ON loans (checked_out_at)')
@TableIndex.sql(
  'CREATE INDEX loans_returned ON loans (returned_at) WHERE returned_at IS NOT NULL',
)
class Loans extends Table {
  TextColumn get id => text()();

  TextColumn get copyId =>
      text().references(Copies, #id, onDelete: KeyAction.restrict)();

  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();

  DateTimeColumn get checkedOutAt => dateTime()();

  TextColumn get dueAt => text().map(const DateOnlyConverter())();

  DateTimeColumn get returnedAt => dateTime().nullable()();

  IntColumn get renewalCount => integer().withDefault(const Constant(0))();

  TextColumn get returnCondition => textEnum<CopyCondition>().nullable()();

  TextColumn get checkedOutByStaffId =>
      text().nullable().references(Staff, #id, onDelete: KeyAction.setNull)();

  TextColumn get returnedByStaffId =>
      text().nullable().references(Staff, #id, onDelete: KeyAction.setNull)();

  IntColumn get ruleLoanPeriodDays => integer()();

  IntColumn get ruleFinePerDay => integer().map(const MoneyConverter())();

  IntColumn get ruleGraceDays => integer()();

  IntColumn get ruleMaximumFine => integer().map(const MoneyConverter())();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
