// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:drift/drift.dart';
import 'package:khulla/core/database/converters/date_only_converter.dart';
import 'package:khulla/features/members/data/tables/member_types.dart';
import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';

/// One borrower on the register.
///
/// Searched through `members_fts` (`members_fts.drift`), kept current by
/// triggers on this table.
@DataClassName('MemberRow')
@TableIndex(name: 'members_barcode', columns: {#barcode}, unique: true)
@TableIndex(name: 'members_type', columns: {#memberTypeId})
@TableIndex.sql(
  'CREATE INDEX members_expiry ON members (expires_at) WHERE archived_at IS NULL',
)
class Members extends Table {
  TextColumn get id => text()();

  TextColumn get barcode => text().unique()();

  TextColumn get fullName => text().withLength(min: 1, max: 160)();

  TextColumn get memberTypeId =>
      text().references(MemberTypes, #id, onDelete: KeyAction.restrict)();

  TextColumn get gender => textEnum<Gender>().nullable()();

  TextColumn get dateOfBirth =>
      text().nullable().map(const DateOnlyConverter())();

  TextColumn get bloodGroup => textEnum<BloodGroup>().nullable()();

  TextColumn get email => text().nullable()();

  TextColumn get phone => text().nullable()();

  TextColumn get address => text().nullable()();

  TextColumn get municipality => text().nullable().withLength(max: 80)();

  TextColumn get occupation => text().nullable().withLength(max: 80)();

  TextColumn get institution => text().nullable().withLength(max: 120)();

  TextColumn get idVerification => text().nullable().withLength(max: 80)();

  TextColumn get emergencyContactName =>
      text().nullable().withLength(max: 80)();

  TextColumn get emergencyContactPhone =>
      text().nullable().withLength(max: 40)();

  TextColumn get guardian => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get joinedAt => dateTime()();

  TextColumn get expiresAt =>
      text().nullable().map(const DateOnlyConverter())();

  DateTimeColumn get suspendedAt => dateTime().nullable()();

  TextColumn get suspensionReason => text().nullable()();

  BoolColumn get sendNotices => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
