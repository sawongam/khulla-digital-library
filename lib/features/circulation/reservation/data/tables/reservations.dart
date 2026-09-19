// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/converters/date_only_converter.dart';
import 'package:khulla/features/catalog/copy/data/tables/copies.dart';
import 'package:khulla/features/catalog/title/data/tables/titles.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';
import 'package:khulla/features/members/data/tables/members.dart';

/// A hold on a title - any copy can satisfy it.
@DataClassName('ReservationRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX reservations_one_active_per_member_title '
  'ON reservations (title_id, member_id) WHERE closed_at IS NULL',
)
@TableIndex.sql(
  'CREATE INDEX reservations_queue ON reservations (title_id, placed_at) '
  'WHERE closed_at IS NULL',
)
// A member's holds, and the lookup a member delete needs.
@TableIndex.sql(
  'CREATE INDEX reservations_member ON reservations (member_id, placed_at)',
)
class Reservations extends Table {
  TextColumn get id => text()();

  TextColumn get titleId =>
      text().references(Titles, #id, onDelete: KeyAction.restrict)();

  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();

  DateTimeColumn get placedAt => dateTime()();

  TextColumn get status => textEnum<ReservationStatus>()();

  TextColumn get readyCopyId =>
      text().nullable().references(Copies, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get readyAt => dateTime().nullable()();

  TextColumn get expiresAt =>
      text().nullable().map(const DateOnlyConverter())();

  DateTimeColumn get closedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  /// [closedAt] and [status] both say whether a hold is open - the partial
  /// indexes read one, the queue logic the other - so the table refuses a
  /// row where they disagree instead of trusting every writer to set both.
  @override
  List<String> get customConstraints => const [
    "CHECK ((closed_at IS NULL) = (status IN ('waiting', 'ready')))",
  ];
}
