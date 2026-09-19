// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/users/domain/user_role.dart';

/// What a location asks of the signed-in role.
class RouteAccess {
  const RouteAccess(this.permission, this.level);

  /// The permission the location sits behind.
  final StaffPermission permission;

  /// How far into that permission the role must reach. [PermissionLevel.view]
  /// for a screen that shows records, [PermissionLevel.manage] for one whose
  /// only purpose is to write them.
  final PermissionLevel level;

  /// Whether [role] may open a location guarded by this.
  bool allows(UserRole role) => switch (level) {
    PermissionLevel.none => true,
    PermissionLevel.view => role.canView(permission),
    PermissionLevel.manage => role.canManage(permission),
  };
}

/// What [location] requires, or null when every signed-in role may open it.
///
/// A pure function of the path so the rule is checkable without a router, a
/// widget tree or a session: `test/app/route_access_test.dart` walks every
/// route against every role through this.
///
/// Two locations are guarded at [PermissionLevel.manage] rather than `view`:
/// the checkout and return desks exist only to write a loan, so opening one
/// with a role that cannot write would render a form whose every button is
/// missing. Everything else asks only that the section be readable, and the
/// controls inside it check `manage` for themselves.
///
/// Ordered longest path first - `/circulation/fines` must not be answered by
/// `/circulation`.
RouteAccess? accessFor(String location) {
  bool under(String prefix) => Routes.isUnder(location, prefix);

  if (under(Routes.circulationCheckOut) || under(Routes.circulationReturn)) {
    return const RouteAccess(
      StaffPermission.circulation,
      PermissionLevel.manage,
    );
  }
  if (under(Routes.circulationFines)) {
    return const RouteAccess(StaffPermission.fines, PermissionLevel.view);
  }
  if (under(Routes.settingsBackup)) {
    return const RouteAccess(StaffPermission.backup, PermissionLevel.view);
  }
  // The theme is this device's preference, not the library's record, and the
  // gallery is a development surface the release build never registers.
  // Neither is settings data, so neither sits behind the settings permission.
  if (under(Routes.settingsAppearance) || under(Routes.settingsDesignSystem)) {
    return null;
  }
  if (under(Routes.settings)) {
    return const RouteAccess(StaffPermission.settings, PermissionLevel.view);
  }
  if (under(Routes.catalog)) {
    return const RouteAccess(StaffPermission.catalog, PermissionLevel.view);
  }
  if (under(Routes.circulation)) {
    return const RouteAccess(
      StaffPermission.circulation,
      PermissionLevel.view,
    );
  }
  if (under(Routes.members)) {
    return const RouteAccess(StaffPermission.members, PermissionLevel.view);
  }
  if (under(Routes.reports)) {
    return const RouteAccess(StaffPermission.reports, PermissionLevel.view);
  }
  if (under(Routes.users)) {
    return const RouteAccess(StaffPermission.users, PermissionLevel.view);
  }
  // The dashboard is the one section every role holds: it is where a blocked
  // location redirects to, so gating it would be a redirect loop.
  return null;
}

/// Where [role] lands when it opens `/settings` itself.
///
/// The section's own redirect cannot be a constant: a role without the
/// settings permission would be sent to the library profile and bounced
/// straight back out, which reads as the rail row doing nothing. Appearance
/// is the floor - every role may theme its own device.
String settingsLandingFor(UserRole role) =>
    role.canView(StaffPermission.settings)
    ? Routes.settingsLibrary
    : Routes.settingsAppearance;
