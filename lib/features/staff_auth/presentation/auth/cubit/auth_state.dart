// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_role.dart';

part 'auth_state.freezed.dart';

/// Where the app stands before it can show anything.
enum AuthStatus {
  /// The catalogue has not been asked yet. The router holds still rather than
  /// guessing - sending a signed-in operator to sign-in for one frame is
  /// worse than a moment of splash.
  unknown,

  /// No staff account exists: this catalogue has never been set up.
  needsSetup,

  /// The library is set up, but nobody is signed in on this device.
  signedOut,

  /// A staff account is signed in.
  signedIn,
}

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.unknown) AuthStatus status,
    StaffMember? staff,
    AppException? error,
  }) = _AuthState;

  const AuthState._();

  /// Whether the catalogue has answered, and the router may redirect.
  bool get isResolved => status != AuthStatus.unknown;

  /// Whether a staff account is signed in on this device.
  bool get isSignedIn => status == AuthStatus.signedIn;

  /// The signed-in account's role, or the most restricted one when nobody is
  /// signed in. There is no safer role to be than the one that changes
  /// nothing.
  UserRole get role => staff?.role ?? UserRole.readOnly;

  /// How far the signed-in account reaches into [permission].
  ///
  /// [PermissionLevel.none] whenever nobody is signed in - there is no
  /// permission to lack more safely than by lacking all of them.
  PermissionLevel levelFor(StaffPermission permission) =>
      staff == null ? PermissionLevel.none : role.levelOf(permission);

  /// Whether the signed-in account may open the section [permission] guards.
  bool canView(StaffPermission permission) => levelFor(permission).canView;

  /// Whether the signed-in account may change what that section holds.
  ///
  /// This is the check every button, menu action and form submit asks. A
  /// screen that only reads asks [canView].
  bool canManage(StaffPermission permission) => levelFor(permission).canManage;
}
