// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/staff_auth/domain/models/session.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';

/// Who is signed in on this device - the one source of truth for it.
///
/// Every layer that needs the signed-in account asks this, never a cubit:
/// a repository attributing a loan reads [requireSignedInStaff], `AuthCubit`
/// mirrors [changes] for the router and the shell, and a sign-in screen
/// hands the account it verified to [startSession]. Cubits therefore never
/// depend on one another to learn who is at the desk.
abstract interface class SessionRepository {
  /// The session as it stands now.
  Session get current;

  /// Every change to [current], in order, from the moment of listening.
  Stream<Session> get changes;

  /// Resolves the starting session: whether the catalogue needs setting up,
  /// and whether the account remembered on this device may still sign in.
  ///
  /// Throws an [AppException] when the catalogue cannot be read; [current]
  /// is left [AuthStatus.unknown] in that case rather than guessed.
  Future<Session> restoreSession();

  /// Signs [staff] in on this device and remembers them for the next start.
  Future<void> startSession(StaffMember staff);

  /// Replaces the signed-in account's details after they were edited, so
  /// the shell shows the new name at once. Ignored for any other account.
  void refreshSignedInStaff(StaffMember staff);

  /// Ends the session on this device. The catalogue is untouched, so the
  /// next screen is sign-in, never onboarding.
  Future<void> endSession();

  /// The signed-in account, for a write that must be attributed to one.
  ///
  /// Throws [SignedOutException] when nobody is signed in - a write is never
  /// recorded against nobody.
  StaffMember requireSignedInStaff();
}
