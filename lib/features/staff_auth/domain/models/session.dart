// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';

part 'session.freezed.dart';

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

/// The signed-in state of this device.
///
/// [staff] is set exactly when [status] is [AuthStatus.signedIn].
@freezed
abstract class Session with _$Session {
  const factory Session({
    @Default(AuthStatus.unknown) AuthStatus status,
    StaffMember? staff,
  }) = _Session;

  const Session._();

  /// Nobody is signed in and nothing has been read yet.
  static const Session unknown = Session();

  bool get isSignedIn => status == AuthStatus.signedIn && staff != null;
}
