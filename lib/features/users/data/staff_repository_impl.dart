// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/security/password_hasher.dart';
import 'package:khulla/core/security/recovery_code.dart';
import 'package:khulla/features/users/data/staff_local_data_source.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';
import 'package:uuid/uuid.dart';

/// [StaffRepository] over the local catalogue.
///
/// The password never travels further than this class: it arrives from a
/// form, is hashed or verified here, and the data source below only ever
/// handles the digest. Recovery codes are hashed the same way before they
/// leave this class.
@LazySingleton(as: StaffRepository)
class StaffRepositoryImpl implements StaffRepository {
  StaffRepositoryImpl(this._dataSource, this._hasher);

  final StaffLocalDataSource _dataSource;
  final PasswordHasher _hasher;

  static const Uuid _uuid = Uuid();

  @override
  Future<bool> hasAnyStaff() => _dataSource.hasAnyStaff();

  @override
  Future<List<StaffMember>> findAllStaff() => _dataSource.findAllStaff();

  @override
  Future<StaffMember?> findStaffById(String id) =>
      _dataSource.findStaffById(id);

  @override
  Future<StaffMember> createStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    List<String> recoveryCodes = const [],
  }) => _dataSource.insertStaff(
    StaffMember(
      id: _uuid.v4(),
      name: name.trim(),
      email: email,
      role: role,
      status: UserStatus.active,
      createdAt: DateTime.now(),
    ),
    passwordHash: _hasher.hash(password),
    recoveryCodeHashes: [
      for (final code in recoveryCodes) RecoveryCode.hash(code),
    ],
  );

  @override
  Future<StaffMember?> signIn({
    required String email,
    required String password,
  }) async {
    final credentials = await _dataSource.findCredentialsByEmail(email);
    if (credentials == null) return null;
    if (!_hasher.verify(password, credentials.passwordHash)) return null;
    // A disabled or never-accepted account is not a sign-in, and saying so
    // would confirm the address exists. The desk re-enables it instead.
    if (!credentials.staff.canSignIn) return null;
    return credentials.staff;
  }

  @override
  Future<bool> hasUnusedRecoveryCodes() => _dataSource.hasUnusedRecoveryCodes();

  @override
  Future<StaffMember?> resetPasswordWithRecoveryCode({
    required String email,
    required String recoveryCode,
    required String newPassword,
  }) async {
    final credentials = await _dataSource.findCredentialsByEmail(email);
    if (credentials == null || !credentials.staff.canSignIn) return null;

    final unused = await _dataSource.findUnusedRecoveryCodes(
      credentials.staff.id,
    );
    StoredRecoveryCode? match;
    for (final stored in unused) {
      if (RecoveryCode.matches(recoveryCode, stored.codeHash)) {
        match = stored;
        break;
      }
    }
    if (match == null) return null;

    try {
      await _dataSource.resetPasswordWithRecoveryCode(
        staffId: credentials.staff.id,
        passwordHash: _hasher.hash(newPassword),
        recoveryCodeId: match.id,
      );
    } on AppException {
      rethrow;
    }
    return credentials.staff;
  }

  @override
  Future<StaffMember> updateStaff({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    required String actingStaffId,
  }) async {
    final current = await _dataSource.findStaffById(id);
    if (current == null) {
      throw const NotFoundException('That staff account no longer exists.');
    }
    // Roles are granted by someone else: a signed-in account cannot change
    // its own role (which would allow self-promotion to administrator or
    // self-demotion away from the last-administrator guard). Name/email
    // edits that keep the role are still allowed.
    if (id == actingStaffId && role != current.role) {
      throw const ConflictException('You cannot change your own role.');
    }
    if (current.role == UserRole.administrator &&
        role != UserRole.administrator) {
      await _guardLastAdministrator();
    }
    return await _dataSource.updateStaff(
      StaffMember(
        id: current.id,
        name: name.trim(),
        email: email,
        role: role,
        status: current.status,
        createdAt: current.createdAt,
      ),
    );
  }

  @override
  Future<StaffMember> setStaffStatus({
    required String id,
    required UserStatus status,
    required String actingStaffId,
  }) async {
    if (status != UserStatus.active) {
      if (id == actingStaffId) {
        throw const ConflictException('You cannot disable your own account.');
      }
      final current = await _dataSource.findStaffById(id);
      if (current?.role == UserRole.administrator) {
        await _guardLastAdministrator();
      }
    }
    return await _dataSource.setStaffStatus(staffId: id, status: status);
  }

  @override
  Future<void> adminResetPassword({
    required String id,
    required String newPassword,
  }) => _dataSource.setPasswordHash(
    staffId: id,
    passwordHash: _hasher.hash(newPassword),
  );

  /// Refuses a change that would leave the library with no active
  /// administrator.
  ///
  /// Called before the target account's role or status is written, so the
  /// count still includes it — "one" here means "only this one, and it is
  /// the one about to lose the role or be disabled".
  Future<void> _guardLastAdministrator() async {
    final activeAdmins = await _dataSource.countStaffWithRoleAndStatus(
      role: UserRole.administrator,
      status: UserStatus.active,
    );
    if (activeAdmins <= 1) {
      throw const ConflictException(
        'The library must always have at least one active administrator.',
      );
    }
  }
}
