// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';

/// Staff accounts and the sign-in that authenticates against them.
abstract interface class StaffRepository {
  /// Whether the library has been set up — that is, whether any staff account
  /// exists. False sends the operator to first-run onboarding.
  Future<bool> hasAnyStaff();

  /// Every account, oldest first.
  Future<List<StaffMember>> findAllStaff();

  /// One account, or null when the id names nothing. Used to restore a saved
  /// session, which is why a missing account is a value and not a failure.
  Future<StaffMember?> findStaffById(String id);

  /// Creates an account with a freshly hashed password.
  ///
  /// [recoveryCodes] are stored as hashes and issued only for the first
  /// administrator. Later accounts omit them.
  ///
  /// Throws a `DuplicateRecordException` when the email is already held.
  Future<StaffMember> createStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    List<String> recoveryCodes = const [],
  });

  /// The account for [email] when [password] verifies against it, and null
  /// when either the address or the password is wrong.
  ///
  /// One null for both cases on purpose: telling a caller which half was
  /// wrong tells anyone holding the file which addresses are real accounts.
  Future<StaffMember?> signIn({
    required String email,
    required String password,
  });

  /// Whether a recovery code can still be spent. The sign-in screen uses this
  /// to offer the recover path only when it can succeed.
  Future<bool> hasUnusedRecoveryCodes();

  /// Sets a new password when [recoveryCode] matches an unused code for the
  /// account at [email], and returns that account. Null when the email, code,
  /// or account status does not allow it — same one-null as [signIn].
  Future<StaffMember?> resetPasswordWithRecoveryCode({
    required String email,
    required String recoveryCode,
    required String newPassword,
  });

  /// Edits name, email and role for an existing account.
  ///
  /// [actingStaffId] is the signed-in administrator making the change — used
  /// to refuse an account demoting itself out of the administrator role, and
  /// to refuse a change that would leave the library with no active
  /// administrator. Throws a `DuplicateRecordException` when [email] is
  /// already held by another account, and a `ConflictException` for either
  /// lockout rule.
  Future<StaffMember> updateStaff({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    required String actingStaffId,
  });

  /// Enables or disables an account.
  ///
  /// Subject to the same lockout rules as [updateStaff]: an account may not
  /// disable itself, and the last active administrator may not be disabled.
  Future<StaffMember> setStaffStatus({
    required String id,
    required UserStatus status,
    required String actingStaffId,
  });

  /// Sets a new password for [id], chosen and typed by an administrator.
  ///
  /// There is no email to send a reset link to in an offline-first app — the
  /// administrator hands the new password to the account holder directly, the
  /// same way the very first administrator's password is set at onboarding.
  Future<void> adminResetPassword({
    required String id,
    required String newPassword,
  });
}
