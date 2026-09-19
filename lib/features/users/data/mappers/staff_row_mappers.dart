// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/users/domain/models/staff_credentials.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';

/// Row ↔ domain conversions for the staff table.
///
/// Mapping lives here and is called only from the data source, so a generated
/// row class never leaves `data/`.
extension StaffRowX on StaffRow {
  /// The account, without its password hash.
  StaffMember toDomain() => StaffMember(
    id: id,
    name: name,
    email: email,
    role: role,
    status: status,
    createdAt: createdAt,
    barcode: barcode,
  );

  /// The account together with the hash to verify a sign-in against.
  StaffCredentials toCredentials() =>
      StaffCredentials(staff: toDomain(), passwordHash: passwordHash);
}

extension StaffMemberX on StaffMember {
  /// The row to write, given an already-computed [passwordHash].
  ///
  /// Hashing is the repository's job, not the mapper's - a mapper that could
  /// hash would be a mapper that could be handed a plaintext password.
  StaffCompanion toCompanion({required String passwordHash}) => StaffCompanion(
    id: Value(id),
    name: Value(name),
    email: Value(email),
    passwordHash: Value(passwordHash),
    role: Value(role),
    status: Value(status),
    barcode: Value(barcode),
    createdAt: Value(createdAt),
  );
}
