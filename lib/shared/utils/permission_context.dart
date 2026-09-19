// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Reads the signed-in role's permissions from anywhere in the widget tree.
///
/// The router keeps a role out of a section it cannot open; this is what
/// keeps it from writing inside a section it *can*. The two are different
/// questions and both have to be asked — a desk assistant may open the
/// catalogue, so the only thing standing between them and an edited title is
/// the check the button makes.
///
/// It watches rather than reads: a role change has to take the buttons away
/// on the frame it happens, not the next time the page is rebuilt for some
/// other reason.
///
/// This is convenience, not security. The catalogue is a file on the
/// operator's own disk, and anyone holding it holds everything in it — see
/// `docs/architecture`. What these checks buy is that a shift cannot make a
/// mistake its role was never meant to be able to make.
extension PermissionContext on BuildContext {
  /// The signed-in account's role — [UserRole.readOnly] when nobody is.
  UserRole get role => watch<AuthCubit>().state.role;

  /// Whether the signed-in role may open the section [permission] guards.
  bool canView(StaffPermission permission) =>
      watch<AuthCubit>().state.canView(permission);

  /// Whether the signed-in role may change what that section holds. The check
  /// every button, menu action and form submit asks.
  bool canManage(StaffPermission permission) =>
      watch<AuthCubit>().state.canManage(permission);
}
