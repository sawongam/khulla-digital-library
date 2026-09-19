// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/features/users/data/tables/staff.dart';

/// One-time codes that reset the first administrator's password.
///
/// Issued only at first-run setup. The plaintext is shown once, then only
/// [codeHash] is kept. Using a code marks [usedAt] so it cannot be replayed.
@DataClassName('StaffRecoveryCodeRow')
@TableIndex(name: 'staff_recovery_codes_staff', columns: {#staffId})
class StaffRecoveryCodes extends Table {
  TextColumn get id => text()();

  TextColumn get staffId =>
      text().references(Staff, #id, onDelete: KeyAction.cascade)();

  /// SHA-256 of the normalized code. Recovery codes have enough entropy that
  /// a slow password hash would only delay setup, not an attacker holding
  /// the file.
  TextColumn get codeHash => text()();

  DateTimeColumn get usedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
