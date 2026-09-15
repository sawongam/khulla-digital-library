// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/app/router/route_access.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/users/domain/user_role.dart';

/// Every location a signed-in operator can reach inside the shell, so a route
/// added without a decision about who may open it fails a test rather than
/// shipping open.
const List<String> _everyLocation = [
  Routes.dashboard,
  Routes.catalogTitles,
  Routes.catalogCopies,
  Routes.catalogLabels,
  Routes.circulationLoans,
  Routes.circulationCheckOut,
  Routes.circulationReturn,
  Routes.circulationReservations,
  Routes.circulationFines,
  Routes.members,
  Routes.reports,
  Routes.users,
  Routes.usersRoles,
  Routes.settingsLibrary,
  Routes.settingsLoanRules,
  Routes.settingsAppearance,
  Routes.settingsBackup,
];

void main() {
  group('rolePermissions', () {
    test('an administrator manages everything', () {
      for (final permission in StaffPermission.values) {
        expect(
          UserRole.administrator.canManage(permission),
          isTrue,
          reason: 'administrator should manage $permission',
        );
      }
    });

    test('read only changes nothing, anywhere', () {
      for (final permission in StaffPermission.values) {
        expect(
          UserRole.readOnly.canManage(permission),
          isFalse,
          reason: 'read only should not manage $permission',
        );
      }
    });

    test('read only still reads the operational sections', () {
      // The role's whole promise: "look at the catalogue and reports, change
      // nothing". A version of it that cannot open the catalogue is a role
      // that can only look at an empty shell.
      for (final permission in [
        StaffPermission.catalog,
        StaffPermission.circulation,
        StaffPermission.members,
        StaffPermission.fines,
        StaffPermission.reports,
      ]) {
        expect(UserRole.readOnly.canView(permission), isTrue);
      }
    });

    test(
      'only an administrator reaches staff, backup and library settings',
      () {
        for (final role in UserRole.values) {
          if (role == UserRole.administrator) continue;
          expect(role.canView(StaffPermission.users), isFalse);
          expect(role.canView(StaffPermission.backup), isFalse);
          expect(role.canManage(StaffPermission.settings), isFalse);
        }
      },
    );

    test('a desk assistant works the counter but not the catalogue', () {
      expect(UserRole.assistant.canManage(StaffPermission.circulation), isTrue);
      expect(UserRole.assistant.canManage(StaffPermission.members), isTrue);
      expect(UserRole.assistant.canView(StaffPermission.catalog), isTrue);
      expect(UserRole.assistant.canManage(StaffPermission.catalog), isFalse);
      // Sees what is owed at the counter; waiving it is a librarian's call.
      expect(UserRole.assistant.canView(StaffPermission.fines), isTrue);
      expect(UserRole.assistant.canManage(StaffPermission.fines), isFalse);
    });

    test('a librarian reads the loan rules without rewriting them', () {
      expect(UserRole.librarian.canView(StaffPermission.settings), isTrue);
      expect(UserRole.librarian.canManage(StaffPermission.settings), isFalse);
    });

    test('an unlisted permission reads as no access, never as a null pass', () {
      // The assistant's map lists four permissions; the other four must come
      // back as `none` rather than throwing or defaulting open.
      expect(
        UserRole.assistant.levelOf(StaffPermission.backup),
        PermissionLevel.none,
      );
    });
  });

  group('accessFor', () {
    test('the dashboard is open to every role', () {
      expect(accessFor(Routes.dashboard), isNull);
    });

    test('the theme is this device, not the library, so nothing guards it', () {
      expect(accessFor(Routes.settingsAppearance), isNull);
    });

    test('a nested path answers to its own section, not its parent', () {
      // `/circulation/fines` is the fines permission, not circulation's, and
      // a prefix test in the wrong order would hand it the parent's answer.
      expect(
        accessFor(Routes.circulationFines)?.permission,
        StaffPermission.fines,
      );
      expect(
        accessFor(Routes.settingsBackup)?.permission,
        StaffPermission.backup,
      );
      expect(accessFor(Routes.usersRoles)?.permission, StaffPermission.users);
    });

    test("a record under a list inherits the list's guard", () {
      expect(
        accessFor(Routes.catalogTitle('t1'))?.permission,
        StaffPermission.catalog,
      );
      expect(
        accessFor(Routes.member('m1'))?.permission,
        StaffPermission.members,
      );
    });

    test('the two desks demand manage, not view', () {
      expect(
        accessFor(Routes.circulationCheckOut)?.level,
        PermissionLevel.manage,
      );
      expect(
        accessFor(Routes.circulationReturn)?.level,
        PermissionLevel.manage,
      );
      // Read only may open circulation, but not a form whose only job is to
      // write a loan.
      expect(
        accessFor(Routes.circulationCheckOut)!.allows(UserRole.readOnly),
        isFalse,
      );
      expect(
        accessFor(Routes.circulationLoans)!.allows(UserRole.readOnly),
        isTrue,
      );
    });

    test('an administrator may open every location', () {
      for (final location in _everyLocation) {
        expect(
          accessFor(location)?.allows(UserRole.administrator) ?? true,
          isTrue,
          reason: 'administrator should reach $location',
        );
      }
    });

    test('every role keeps a landing place it can open', () {
      // The redirect for a blocked location is the dashboard, so a role that
      // could not open the dashboard would loop.
      for (final role in UserRole.values) {
        expect(accessFor(Routes.dashboard)?.allows(role) ?? true, isTrue);
      }
    });

    test('the sections a role cannot see are refused by path too', () {
      // The rail hides these; this is the typed URL and the stale bookmark.
      for (final location in [
        Routes.users,
        Routes.usersRoles,
        Routes.settingsBackup,
        Routes.settingsLibrary,
      ]) {
        expect(
          accessFor(location)!.allows(UserRole.assistant),
          isFalse,
          reason: 'assistant should be refused $location',
        );
      }
    });

    test('settings opens where the role can actually land', () {
      expect(
        settingsLandingFor(UserRole.administrator),
        Routes.settingsLibrary,
      );
      expect(settingsLandingFor(UserRole.librarian), Routes.settingsLibrary);
      // Neither of these can read the library's settings, so sending them to
      // the profile would bounce them straight back to the dashboard.
      expect(settingsLandingFor(UserRole.assistant), Routes.settingsAppearance);
      expect(settingsLandingFor(UserRole.readOnly), Routes.settingsAppearance);
      for (final role in UserRole.values) {
        final landing = settingsLandingFor(role);
        expect(accessFor(landing)?.allows(role) ?? true, isTrue);
      }
    });
  });
}
