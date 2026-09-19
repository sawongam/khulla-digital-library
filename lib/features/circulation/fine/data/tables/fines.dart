// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/converters/money_converter.dart';
import 'package:khulla/features/circulation/loan/data/tables/loans.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/members/data/tables/members.dart';

/// Money actually owed - written at return or manual assessment.
@DataClassName('FineRow')
@TableIndex.sql(
  'CREATE INDEX fines_outstanding ON fines (member_id) WHERE paid + waived < assessed',
)
// A member's whole fine history, and the lookup a member delete needs -
// `fines_outstanding` is partial, so it serves neither.
@TableIndex.sql(
  'CREATE INDEX fines_member ON fines (member_id, raised_at DESC)',
)
// Date-range reads on the dashboard and reports, and recent activity.
@TableIndex.sql('CREATE INDEX fines_raised ON fines (raised_at)')
class Fines extends Table {
  TextColumn get id => text()();

  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();

  TextColumn get loanId =>
      text().nullable().references(Loans, #id, onDelete: KeyAction.restrict)();

  TextColumn get reason => textEnum<FineReason>()();

  IntColumn get assessed => integer().map(const MoneyConverter())();

  IntColumn get paid =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();

  IntColumn get waived =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();

  DateTimeColumn get raisedAt => dateTime()();

  DateTimeColumn get settledAt => dateTime().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (assessed >= 0)',
    'CHECK (paid >= 0)',
    'CHECK (waived >= 0)',
    'CHECK (paid + waived <= assessed)',
  ];
}
