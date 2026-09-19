// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/staff_auth/data/auth_session_storage.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_state.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';

/// The app-wide session: whether this catalogue has been set up, and who is
/// signed in.
///
/// The router redirects on [AuthState.status], so this cubit is the only
/// thing deciding whether the operator sees onboarding, sign-in, or the
/// shell. It is a [lazySingleton] and therefore never closed - no `isClosed`
/// guards here, deliberately.
///
/// It has no page of its own. Sign-in and onboarding own their forms and hand
/// the finished account over with [startSession].
@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._staff, this._storage) : super(const AuthState());

  final StaffRepository _staff;
  final AuthSessionStorage _storage;

  /// Resolves the starting status: set up or not, signed in or not.
  ///
  /// Called from `bootstrap` before the first frame so the router's first
  /// redirect already knows the answer. A failure to read leaves the status
  /// [AuthStatus.unknown] with the error in state - the catalogue is not
  /// answering, and guessing "needs setup" would offer to create a second
  /// administrator over the top of a real library.
  Future<void> restoreSession() async {
    try {
      if (!await _staff.hasAnyStaff()) {
        emit(const AuthState(status: AuthStatus.needsSetup));
        return;
      }

      final staffId = _storage.readStaffId();
      final staff = staffId == null
          ? null
          : await _staff.findStaffById(staffId);

      // A remembered account that has since been deleted or disabled is not a
      // session. Drop the stored id so the next start does not retry it.
      if (staff == null || !staff.canSignIn) {
        if (staffId != null) await _storage.clearStaffId();
        emit(const AuthState(status: AuthStatus.signedOut));
        return;
      }

      emit(AuthState(status: AuthStatus.signedIn, staff: staff));
    } on AppException catch (error) {
      emit(AuthState(error: error));
    }
  }

  /// Signs [staff] in on this device and remembers them for the next start.
  ///
  /// Called by sign-in and by the last step of onboarding, so there is one
  /// place that decides what "signed in" means.
  Future<void> startSession(StaffMember staff) async {
    emit(AuthState(status: AuthStatus.signedIn, staff: staff));
    await _storage.saveStaffId(staff.id);
  }

  /// Updates the signed-in account in memory when its details change.
  void updateStaff(StaffMember staff) {
    if (state.status == AuthStatus.signedIn && state.staff?.id == staff.id) {
      emit(state.copyWith(staff: staff));
    }
  }

  /// Ends the session on this device. The catalogue is untouched, so the next
  /// screen is sign-in and never onboarding.
  Future<void> signOut() async {
    emit(const AuthState(status: AuthStatus.signedOut));
    await _storage.clearStaffId();
  }
}
