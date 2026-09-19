// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// What a staff account is allowed to do.
///
/// Roles are a fixed set rather than a table because a library's desk has
/// four jobs, not an arbitrary number: the person who owns the system, the
/// people who run the catalogue, the people who work the counter, and anyone
/// who may look but not touch. A custom role is a feature request, not a
/// default.
enum UserRole { administrator, librarian, assistant, readOnly }

/// One thing a role may or may not do.
///
/// The list is deliberately coarse - eight permissions a librarian can reason
/// about, not forty a developer can. Anything finer belongs to the screen
/// that enforces it.
enum StaffPermission {
  catalog,
  circulation,
  members,
  fines,
  reports,
  settings,
  users,
  backup,
}

/// How far a role reaches into one [StaffPermission].
///
/// Two levels rather than one flag, because "read only" is a role this
/// library ships and a boolean cannot express it: a desk assistant must be
/// able to look a book up without being able to edit its record, and that is
/// the same permission at two different depths. [view] opens the section and
/// its screens; [manage] additionally unlocks every control that writes.
enum PermissionLevel {
  /// The section is not reachable at all - hidden in the shell, and
  /// redirected away from if its URL is typed.
  none,

  /// The section opens, and every control that would change something is
  /// gone. Not disabled: a button that can never be pressed is furniture.
  view,

  /// The section opens and can be changed.
  manage;

  /// Whether this level opens the section at all.
  bool get canView => this != none;

  /// Whether this level may change what the section holds.
  bool get canManage => this == manage;
}

/// The permissions each role carries, and how deeply.
///
/// Written out per role rather than derived from a hierarchy: a desk
/// assistant is not "a librarian with less", and the day that stops being
/// true this map is the one place that changes. A permission a role does not
/// list at all is [PermissionLevel.none] - read it through
/// [UserRolePermissions.levelOf] rather than indexing, so a missing entry can
/// never read as access.
const Map<UserRole, Map<StaffPermission, PermissionLevel>> rolePermissions = {
  UserRole.administrator: {
    StaffPermission.catalog: PermissionLevel.manage,
    StaffPermission.circulation: PermissionLevel.manage,
    StaffPermission.members: PermissionLevel.manage,
    StaffPermission.fines: PermissionLevel.manage,
    StaffPermission.reports: PermissionLevel.manage,
    StaffPermission.settings: PermissionLevel.manage,
    StaffPermission.users: PermissionLevel.manage,
    StaffPermission.backup: PermissionLevel.manage,
  },
  UserRole.librarian: {
    StaffPermission.catalog: PermissionLevel.manage,
    StaffPermission.circulation: PermissionLevel.manage,
    StaffPermission.members: PermissionLevel.manage,
    StaffPermission.fines: PermissionLevel.manage,
    StaffPermission.reports: PermissionLevel.manage,
    // The library's own settings are readable - a librarian answering "how
    // long is a loan" should not have to ask an administrator - but the loan
    // rules and the library's identity are the administrator's to change.
    StaffPermission.settings: PermissionLevel.view,
  },
  // "The circulation desk: check out, return, and look up a member." Looking
  // a book up is catalogue work, so the catalogue opens; editing its records
  // is not, so it opens read-only. Fines are visible at the counter - a
  // member's standing decides whether they may borrow - but waiving one is a
  // librarian's call.
  UserRole.assistant: {
    StaffPermission.catalog: PermissionLevel.view,
    StaffPermission.circulation: PermissionLevel.manage,
    StaffPermission.members: PermissionLevel.manage,
    StaffPermission.fines: PermissionLevel.view,
  },
  // "Look at the catalogue and reports. Change nothing." Every operational
  // section opens; nothing in any of them writes.
  UserRole.readOnly: {
    StaffPermission.catalog: PermissionLevel.view,
    StaffPermission.circulation: PermissionLevel.view,
    StaffPermission.members: PermissionLevel.view,
    StaffPermission.fines: PermissionLevel.view,
    StaffPermission.reports: PermissionLevel.view,
  },
};

extension UserRolePermissions on UserRole {
  /// How far this role reaches into [permission].
  ///
  /// The only supported way to read [rolePermissions]: an unlisted role or an
  /// unlisted permission is [PermissionLevel.none], never an access check
  /// that silently passes on a null.
  PermissionLevel levelOf(StaffPermission permission) =>
      rolePermissions[this]?[permission] ?? PermissionLevel.none;

  /// Whether this role may open the section [permission] guards.
  bool canView(StaffPermission permission) => levelOf(permission).canView;

  /// Whether this role may change what that section holds.
  bool canManage(StaffPermission permission) => levelOf(permission).canManage;
}
