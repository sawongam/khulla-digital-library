// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/security/password_hasher.dart';
import 'package:khulla/core/security/recovery_code.dart';
import 'package:khulla/features/staff_auth/data/session_repository_impl.dart';
import 'package:khulla/features/users/data/local_staff_data_source.dart';
import 'package:khulla/features/users/data/staff_repository_impl.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';

import '../helpers/test_database.dart';
import '../helpers/test_session.dart';

void main() {
  late AppDatabase db;
  late SessionRepositoryImpl session;
  late StaffRepositoryImpl repository;

  setUp(() async {
    db = await openTestDatabase();
    session = await openTestSession(db);
    repository = StaffRepositoryImpl(
      LocalStaffDataSource(db),
      PasswordHasher(),
      session,
    );
  });

  tearDown(() => closeTestDatabase(db));

  test('resetPasswordWithRecoveryCode spends one code and signs in', () async {
    final codes = RecoveryCode.generateSet();
    await repository.createStaff(
      name: 'Ram',
      email: 'ram@lib.np',
      password: 'correct-horse',
      role: UserRole.administrator,
      recoveryCodes: codes,
    );

    expect(await repository.hasUnusedRecoveryCodes(), isTrue);
    expect(
      await repository.signIn(email: 'ram@lib.np', password: 'wrong'),
      isNull,
    );

    final recovered = await repository.resetPasswordWithRecoveryCode(
      email: 'ram@lib.np',
      recoveryCode: codes.first.toLowerCase(),
      newPassword: 'new-password',
    );
    expect(recovered, isNotNull);
    expect(recovered!.email, 'ram@lib.np');

    expect(
      await repository.resetPasswordWithRecoveryCode(
        email: 'ram@lib.np',
        recoveryCode: codes.first,
        newPassword: 'another-password',
      ),
      isNull,
    );

    expect(
      await repository.signIn(email: 'ram@lib.np', password: 'correct-horse'),
      isNull,
    );
    final signedIn = await repository.signIn(
      email: 'ram@lib.np',
      password: 'new-password',
    );
    expect(signedIn, isNotNull);

    expect(await repository.hasUnusedRecoveryCodes(), isTrue);
  });

  test('resetPasswordWithRecoveryCode returns null for a wrong code', () async {
    await repository.createStaff(
      name: 'Sita',
      email: 'sita@lib.np',
      password: 'correct-horse',
      role: UserRole.administrator,
      recoveryCodes: RecoveryCode.generateSet(),
    );

    expect(
      await repository.resetPasswordWithRecoveryCode(
        email: 'sita@lib.np',
        recoveryCode: 'AAAA-AAAA-AAAA-AAAA',
        newPassword: 'new-password',
      ),
      isNull,
    );
    expect(
      await repository.signIn(email: 'sita@lib.np', password: 'correct-horse'),
      isNotNull,
    );
  });

  test('updateStaff replaces name, email and role', () async {
    final admin = await repository.createStaff(
      name: 'Ram',
      email: 'ram@lib.np',
      password: 'correct-horse',
      role: UserRole.administrator,
    );
    final librarian = await repository.createStaff(
      name: 'Sita',
      email: 'sita@lib.np',
      password: 'correct-horse',
      role: UserRole.librarian,
    );

    await session.startSession(admin);
    final updated = await repository.updateStaff(
      id: librarian.id,
      name: 'Sita Rai',
      email: 'sita.rai@lib.np',
      role: UserRole.assistant,
    );

    expect(updated.name, 'Sita Rai');
    expect(updated.email, 'sita.rai@lib.np');
    expect(updated.role, UserRole.assistant);
  });

  test('updateStaff throws when the email is already held', () async {
    final admin = await repository.createStaff(
      name: 'Ram',
      email: 'ram@lib.np',
      password: 'correct-horse',
      role: UserRole.administrator,
    );
    final librarian = await repository.createStaff(
      name: 'Sita',
      email: 'sita@lib.np',
      password: 'correct-horse',
      role: UserRole.librarian,
    );

    await session.startSession(admin);
    expect(
      () => repository.updateStaff(
        id: librarian.id,
        name: librarian.name,
        email: 'ram@lib.np',
        role: librarian.role,
      ),
      throwsA(isA<DuplicateRecordException>()),
    );
  });

  test('updateStaff refuses to demote the last active administrator', () async {
    final admin = await repository.createStaff(
      name: 'Ram',
      email: 'ram@lib.np',
      password: 'correct-horse',
      role: UserRole.administrator,
    );

    await session.startSession(admin);
    expect(
      () => repository.updateStaff(
        id: admin.id,
        name: admin.name,
        email: admin.email,
        role: UserRole.librarian,
      ),
      throwsA(isA<ConflictException>()),
    );
  });

  test(
    'updateStaff allows demoting an administrator when another one is active',
    () async {
      final first = await repository.createStaff(
        name: 'Ram',
        email: 'ram@lib.np',
        password: 'correct-horse',
        role: UserRole.administrator,
      );
      final second = await repository.createStaff(
        name: 'Gita',
        email: 'gita@lib.np',
        password: 'correct-horse',
        role: UserRole.administrator,
      );

      await session.startSession(first);
      final demoted = await repository.updateStaff(
        id: second.id,
        name: second.name,
        email: second.email,
        role: UserRole.librarian,
      );

      expect(demoted.role, UserRole.librarian);
    },
  );

  test('setStaffStatus refuses to disable your own account', () async {
    final admin = await repository.createStaff(
      name: 'Ram',
      email: 'ram@lib.np',
      password: 'correct-horse',
      role: UserRole.administrator,
    );

    await session.startSession(admin);
    expect(
      () => repository.setStaffStatus(
        id: admin.id,
        status: UserStatus.disabled,
      ),
      throwsA(isA<ConflictException>()),
    );
  });

  test(
    'setStaffStatus refuses to disable the last active administrator',
    () async {
      final admin = await repository.createStaff(
        name: 'Ram',
        email: 'ram@lib.np',
        password: 'correct-horse',
        role: UserRole.administrator,
      );
      final librarian = await repository.createStaff(
        name: 'Sita',
        email: 'sita@lib.np',
        password: 'correct-horse',
        role: UserRole.librarian,
      );

      await session.startSession(librarian);
      expect(
        () => repository.setStaffStatus(
          id: admin.id,
          status: UserStatus.disabled,
        ),
        throwsA(isA<ConflictException>()),
      );
    },
  );

  test(
    'setStaffStatus disables and re-enables a non-administrator account',
    () async {
      final admin = await repository.createStaff(
        name: 'Ram',
        email: 'ram@lib.np',
        password: 'correct-horse',
        role: UserRole.administrator,
      );
      final librarian = await repository.createStaff(
        name: 'Sita',
        email: 'sita@lib.np',
        password: 'correct-horse',
        role: UserRole.librarian,
      );

      await session.startSession(admin);
      final disabled = await repository.setStaffStatus(
        id: librarian.id,
        status: UserStatus.disabled,
      );
      expect(disabled.status, UserStatus.disabled);
      expect(
        await repository.signIn(
          email: 'sita@lib.np',
          password: 'correct-horse',
        ),
        isNull,
      );

      await session.startSession(admin);
      final enabled = await repository.setStaffStatus(
        id: librarian.id,
        status: UserStatus.active,
      );
      expect(enabled.status, UserStatus.active);
      expect(
        await repository.signIn(
          email: 'sita@lib.np',
          password: 'correct-horse',
        ),
        isNotNull,
      );
    },
  );

  test('adminResetPassword sets a new password directly', () async {
    final admin = await repository.createStaff(
      name: 'Ram',
      email: 'ram@lib.np',
      password: 'correct-horse',
      role: UserRole.administrator,
    );
    final librarian = await repository.createStaff(
      name: 'Sita',
      email: 'sita@lib.np',
      password: 'correct-horse',
      role: UserRole.librarian,
    );

    await repository.adminResetPassword(
      id: librarian.id,
      newPassword: 'brand-new-password',
    );

    expect(
      await repository.signIn(email: 'sita@lib.np', password: 'correct-horse'),
      isNull,
    );
    expect(
      await repository.signIn(
        email: 'sita@lib.np',
        password: 'brand-new-password',
      ),
      isNotNull,
    );
    // Unrelated to the account being reset - the administrator's own
    // password never moves.
    expect(
      await repository.signIn(email: admin.email, password: 'correct-horse'),
      isNotNull,
    );
  });
}
