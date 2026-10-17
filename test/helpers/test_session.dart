// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/staff_auth/data/auth_session_storage.dart';
import 'package:khulla/features/staff_auth/data/session_repository_impl.dart';
import 'package:khulla/features/users/data/local_staff_data_source.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A real [SessionRepositoryImpl] over [db], with in-memory preferences and
/// nobody signed in.
Future<SessionRepositoryImpl> openTestSession(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return SessionRepositoryImpl(
    LocalStaffDataSource(db),
    AuthSessionStorage(prefs),
  );
}

/// Inserts a staff account into [db] and signs it in on [session].
///
/// Loans reference the staff table, so a desk write in a test needs an
/// account that exists rather than a made-up id.
Future<StaffMember> signInTestStaff(
  AppDatabase db,
  SessionRepositoryImpl session, {
  String email = 'desk@library.test',
  UserRole role = UserRole.administrator,
}) async {
  final staff = await LocalStaffDataSource(db).insertStaff(
    StaffMember(
      id: 'staff-$email',
      name: 'Desk Staff',
      email: email,
      role: role,
      status: UserStatus.active,
      createdAt: DateTime(2026),
    ),
    passwordHash: 'not-a-real-hash',
  );
  await session.startSession(staff);
  return staff;
}
