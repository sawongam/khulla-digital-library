// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/staff_auth/data/auth_session_storage.dart';
import 'package:khulla/features/staff_auth/data/session_repository_impl.dart';
import 'package:khulla/features/staff_auth/domain/models/session.dart';
import 'package:khulla/features/users/data/local_staff_data_source.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';
import '../helpers/test_session.dart';

/// [SessionRepositoryImpl] - the one place that knows who is signed in -
/// against a real staff table.
void main() {
  late AppDatabase db;
  late SessionRepositoryImpl session;

  setUp(() async {
    db = await openTestDatabase();
    session = await openTestSession(db);
  });

  tearDown(() => closeTestDatabase(db));

  test('an empty catalogue needs setting up', () async {
    final restored = await session.restoreSession();

    expect(restored.status, AuthStatus.needsSetup);
    expect(session.current, restored);
  });

  test('a catalogue with staff and nobody remembered is signed out', () async {
    await LocalStaffDataSource(db).insertStaff(
      _staff('someone@library.test'),
      passwordHash: 'unused',
    );

    final restored = await session.restoreSession();

    expect(restored.status, AuthStatus.signedOut);
    expect(
      () => session.requireSignedInStaff(),
      throwsA(isA<SignedOutException>()),
    );
  });

  test('a remembered account is restored on the next start', () async {
    final staff = await signInTestStaff(db, session);

    final prefs = await SharedPreferences.getInstance();
    final nextStart = SessionRepositoryImpl(
      LocalStaffDataSource(db),
      AuthSessionStorage(prefs),
    );
    final restored = await nextStart.restoreSession();

    expect(restored.status, AuthStatus.signedIn);
    expect(nextStart.requireSignedInStaff().id, staff.id);
  });

  test('a remembered account that was disabled is not restored', () async {
    final staff = await signInTestStaff(db, session);
    await LocalStaffDataSource(
      db,
    ).setStaffStatus(staffId: staff.id, status: UserStatus.disabled);

    final restored = await session.restoreSession();

    expect(restored.status, AuthStatus.signedOut);
    final prefs = await SharedPreferences.getInstance();
    expect(AuthSessionStorage(prefs).readStaffId(), isNull);
  });

  test(
    'changes are announced in order, and ending a session ends it',
    () async {
      final seen = <AuthStatus>[];
      final subscription = session.changes.listen(
        (change) => seen.add(change.status),
      );

      await signInTestStaff(db, session);
      await session.endSession();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen, [AuthStatus.signedIn, AuthStatus.signedOut]);
      expect(
        () => session.requireSignedInStaff(),
        throwsA(isA<SignedOutException>()),
      );
    },
  );

  test(
    'editing the signed-in account refreshes it; others are ignored',
    () async {
      final staff = await signInTestStaff(db, session);

      session.refreshSignedInStaff(_staff('other@library.test'));
      expect(session.requireSignedInStaff().name, staff.name);

      session.refreshSignedInStaff(staff.copyWith(name: 'Renamed'));
      expect(session.requireSignedInStaff().name, 'Renamed');
    },
  );
}

StaffMember _staff(String email) => StaffMember(
  id: 'staff-$email',
  name: 'Desk Staff',
  email: email,
  role: UserRole.librarian,
  status: UserStatus.active,
  createdAt: DateTime(2026),
);
