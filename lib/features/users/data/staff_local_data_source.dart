// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/users/domain/models/staff_credentials.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';

/// An unused recovery-code row: its id and the stored digest.
class StoredRecoveryCode {
  const StoredRecoveryCode({required this.id, required this.codeHash});

  final String id;
  final String codeHash;
}

/// Reads and writes staff accounts in the local catalogue.
abstract interface class StaffLocalDataSource {
  /// Whether any staff account exists.
  ///
  /// This is the setup gate the router gates on, so it is a count and not a
  /// full read: on a fresh install it has to answer before the first frame.
  Future<bool> hasAnyStaff();

  /// Every account, oldest first - the order the desk was staffed in.
  Future<List<StaffMember>> findAllStaff();

  /// One account, or null when the id names nothing.
  Future<StaffMember?> findStaffById(String id);

  /// The account for [email] together with its password hash, or null when no
  /// account holds that address. [email] is normalized here, so a caller may
  /// pass exactly what the operator typed.
  Future<StaffCredentials?> findCredentialsByEmail(String email);

  /// Whether any recovery code has not yet been spent. Drives the sign-in
  /// recover link: no unused codes means that path cannot succeed.
  Future<bool> hasUnusedRecoveryCodes();

  /// Unused recovery codes for [staffId], oldest first.
  Future<List<StoredRecoveryCode>> findUnusedRecoveryCodes(String staffId);

  /// Writes [staff] with [passwordHash] and optional recovery-code digests.
  ///
  /// Throws a `DuplicateRecordException` when the email is already held.
  Future<StaffMember> insertStaff(
    StaffMember staff, {
    required String passwordHash,
    List<String> recoveryCodeHashes = const [],
  });

  /// Replaces the password digest and marks one recovery code as spent.
  Future<void> resetPasswordWithRecoveryCode({
    required String staffId,
    required String passwordHash,
    required String recoveryCodeId,
  });

  /// Every account currently holding [role] with [status], across the whole
  /// register. Used to check the "at least one active administrator"
  /// invariant before a write, so the check and the write see the same count.
  Future<int> countStaffWithRoleAndStatus({
    required UserRole role,
    required UserStatus status,
  });

  /// Replaces name, email and role for the account named by [staff]'s id.
  ///
  /// Throws a `DuplicateRecordException` when the email is already held by a
  /// different account.
  Future<StaffMember> updateStaff(StaffMember staff);

  /// Replaces the status for [staffId].
  Future<StaffMember> setStaffStatus({
    required String staffId,
    required UserStatus status,
  });

  /// Replaces the password digest for [staffId], outside the recovery-code
  /// flow - an administrator setting it directly.
  Future<void> setPasswordHash({
    required String staffId,
    required String passwordHash,
  });
}
