// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:drift/drift.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';

/// Staff accounts — the people who run the library from behind the desk.
///
/// This is the table that answers "has this library been set up yet?": a
/// catalogue with no staff row has never been through first-run setup, and
/// the app sends the operator to onboarding instead of sign-in. The first row
/// is always an administrator; the rest are added later from the staff
/// section.
///
/// Borrowers are **not** here. A member borrows books and a staff member
/// operates the system; the two have different fields, different lifetimes,
/// and only one of them signs in.
@DataClassName('StaffRow')
@TableIndex(name: 'staff_barcode', columns: {#barcode}, unique: true)
class Staff extends Table {
  /// A UUID rather than a rowid, so an account keeps its identity across an
  /// export, a restore, or a catalogue merged from a second branch.
  TextColumn get id => text()();

  /// Display name, shown on the account control and against every action the
  /// person takes.
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// The sign-in identifier, stored already lower-cased and trimmed.
  ///
  /// Uniqueness is enforced here rather than checked before the insert: two
  /// windows onto the same file can both find an address free and then both
  /// write it. Normalizing on the way in is what makes the constraint mean
  /// what a person expects — `Ram@Lib.np` and `ram@lib.np` are one account.
  TextColumn get email => text().withLength(min: 3, max: 254).unique()();

  /// A salted bcrypt digest. Never the password itself, and never reversible.
  /// The first administrator can reset theirs with a one-time recovery code;
  /// later accounts are reset by an administrator under Staff.
  TextColumn get passwordHash => text()();

  /// What the account is allowed to do. Stored as the enum's name so the set
  /// can be reordered without rewriting rows.
  TextColumn get role => textEnum<UserRole>()();

  /// Whether the account may sign in. Disabling is preferred to deleting: the
  /// record is referenced by everything the person did at the desk.
  TextColumn get status => textEnum<UserStatus>()();

  /// Auto-generated staff barcode — unique, shown on detail and for scans.
  TextColumn get barcode => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
