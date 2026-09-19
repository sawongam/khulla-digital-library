// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One section of the app, as the shell's navigation describes it.
///
/// This list is the single source of truth for navigation: index `i` here is
/// `StatefulShellBranch` `i` in `AppRouter`, the same list feeds the rail on a
/// window and the bottom bar on a phone, and [children] gives the rail the
/// sub-sections a branch contains without the router being asked twice.
///
/// The list itself is never filtered by role — every branch stays at its
/// fixed index, because the rail's `onDestinationSelected` calls
/// `navigationShell.goBranch(index)` with that same index. `AppShell` is
/// where a role that lacks [permission] skips an entry, using its original
/// index rather than its position among the ones actually shown.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.route,
    this.children = const [],
    this.primary = false,
    this.permission,
    this.expandedByDefault = false,
  });

  /// The section's name.
  final String label;

  /// The section's glyph. One glyph serves both states — selection reads
  /// through colour, not through a heavier weight.
  final AppIconSpec icon;

  /// The branch's root route.
  final String route;

  /// The routes nested under it, listed in the extended rail.
  final List<ShellChild> children;

  /// Whether the section earns a slot in the compact bottom bar, which holds
  /// four before it starts eating labels. Everything else lives behind
  /// *More*.
  final bool primary;

  /// The permission a signed-in role must be able to *view* for this section
  /// to appear at all. Null means every role sees it — the dashboard, and
  /// settings, which holds this device's own theme.
  ///
  /// Seeing a section is not being able to change it: the controls inside ask
  /// `canManage` for themselves through `PermissionContext`.
  final StaffPermission? permission;

  /// Whether this group starts expanded in the extended rail. Only one
  /// section should opt in, so first paint stays compact.
  final bool expandedByDefault;
}

/// One route nested under a [ShellDestination].
class ShellChild {
  const ShellChild({required this.label, required this.route});

  /// The sub-section's name.
  final String label;

  /// Where it goes.
  final String route;
}

/// Whether [route] is the selected entry for [location] among
/// [siblingRoutes].
///
/// Routes nest — `/users` contains `/users/roles` — so a plain prefix test
/// marks every ancestor as selected and two rows light up at once. Only the
/// longest, most specific match reads as selected; the ancestors stay visible
/// through the expanded group itself.
bool isSelectedShellRoute(
  String location,
  String route,
  List<String> siblingRoutes,
) {
  if (!Routes.isUnder(location, route)) return false;
  for (final sibling in siblingRoutes) {
    if (sibling.length > route.length && Routes.isUnder(location, sibling)) {
      return false;
    }
  }
  return true;
}

/// The shell's destinations, in display order.
///
/// The order is a shift's order, not an alphabet: a desk shift starts by
/// looking at what is out and overdue, then works the catalogue and the desk,
/// then the people. Reports, staff and settings are the things you open once
/// a week, so they sit under the daily work rather than above it.
///
/// [role] decides which *children* are listed, because a child is only ever
/// a link. A branch is different: filtering one out of this list would desync
/// it from the router's branch indices (see [ShellDestination]), so a branch
/// a role cannot open still appears here with its
/// [ShellDestination.permission] set, and it is `AppShell`'s job to skip it
/// without breaking that index.
///
/// The manual is the one branch with no entry here: it opens from the
/// account menu (and the phone's *More* sheet) rather than the rail, so it
/// needs no rail index — only a branch, so it renders inside the shell.
List<ShellDestination> shellDestinations(
  AppLocalizations l10n,
  UserRole role,
) {
  final canSeeSettings = role.canView(StaffPermission.settings);
  final canWorkTheDesk = role.canManage(StaffPermission.circulation);

  return [
    ShellDestination(
      label: l10n.navDashboard,
      icon: AppIcons.dashboard,
      route: Routes.dashboard,
      primary: true,
    ),
    ShellDestination(
      label: l10n.navCatalog,
      icon: AppIcons.book,
      route: Routes.catalog,
      primary: true,
      permission: StaffPermission.catalog,
      expandedByDefault: true,
      children: [
        ShellChild(label: l10n.navCatalogTitles, route: Routes.catalogTitles),
        ShellChild(label: l10n.navCatalogCopies, route: Routes.catalogCopies),
        ShellChild(label: l10n.navCatalogLabels, route: Routes.catalogLabels),
      ],
    ),
    ShellDestination(
      label: l10n.navCirculation,
      icon: AppIcons.transfer,
      route: Routes.circulation,
      primary: true,
      permission: StaffPermission.circulation,
      expandedByDefault: true,
      children: [
        ShellChild(
          label: l10n.navCirculationLoans,
          route: Routes.circulationLoans,
        ),
        // The two desks exist only to write a loan. A role that may read
        // circulation but not work it gets the loan list and the hold queue,
        // not a checkout form with nothing that submits.
        if (canWorkTheDesk) ...[
          ShellChild(
            label: l10n.navCirculationCheckOut,
            route: Routes.circulationCheckOut,
          ),
          ShellChild(
            label: l10n.navCirculationReturn,
            route: Routes.circulationReturn,
          ),
        ],
        ShellChild(
          label: l10n.navCirculationReservations,
          route: Routes.circulationReservations,
        ),
        if (role.canView(StaffPermission.fines))
          ShellChild(
            label: l10n.navCirculationFines,
            route: Routes.circulationFines,
          ),
      ],
    ),
    ShellDestination(
      label: l10n.navMembers,
      icon: AppIcons.people,
      route: Routes.members,
      primary: true,
      permission: StaffPermission.members,
    ),
    ShellDestination(
      label: l10n.navReports,
      icon: AppIcons.insights,
      route: Routes.reports,
      permission: StaffPermission.reports,
    ),
    ShellDestination(
      label: l10n.navUsers,
      icon: AppIcons.idCard,
      route: Routes.users,
      permission: StaffPermission.users,
      children: [
        ShellChild(label: l10n.navUsersAccounts, route: Routes.users),
        ShellChild(label: l10n.navUsersRoles, route: Routes.usersRoles),
      ],
    ),
    ShellDestination(
      label: l10n.navSettings,
      icon: AppIcons.settings,
      route: Routes.settings,
      children: [
        if (canSeeSettings) ...[
          ShellChild(
            label: l10n.navSettingsLibrary,
            route: Routes.settingsLibrary,
          ),
          ShellChild(
            label: l10n.navSettingsLoanRules,
            route: Routes.settingsLoanRules,
          ),
        ],
        // The theme is this device's preference rather than the library's
        // record, so it stays with every role — including the one that may
        // change nothing else.
        ShellChild(
          label: l10n.navSettingsAppearance,
          route: Routes.settingsAppearance,
        ),
        if (role.canView(StaffPermission.backup))
          ShellChild(
            label: l10n.navSettingsBackup,
            route: Routes.settingsBackup,
          ),
      ],
    ),
  ];
}
