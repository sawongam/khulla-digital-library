// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/sign_in/cubit/sign_in_state.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';

/// The sign-in form.
///
/// It owns the form and nothing else: on success it hands the account to
/// [AuthCubit], which is what the router watches. That is why this cubit can
/// be scoped to the page and die with it.
@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._staff, this._auth) : super(const SignInState());

  final StaffRepository _staff;
  final AuthCubit _auth;

  void emailChanged(String value) => emit(
    state.copyWith(
      email: Email.dirty(value),
      credentialsRejected: false,
      error: null,
    ),
  );

  void passwordChanged(String value) => emit(
    state.copyWith(
      password: Password.dirty(value),
      credentialsRejected: false,
      error: null,
    ),
  );

  /// Offers the recover path only when an unused code still exists.
  Future<void> loadRecoveryAvailability() async {
    try {
      final canRecover = await _staff.hasUnusedRecoveryCodes();
      if (isClosed) return;
      emit(
        state.copyWith(
          canRecoverPassword: canRecover,
          recoveryAvailabilityLoaded: true,
        ),
      );
    } on AppException {
      if (isClosed) return;
      emit(state.copyWith(recoveryAvailabilityLoaded: true));
    }
  }

  /// Verifies the credentials and, when they hold, opens the session.
  ///
  /// A rejection is a state, not a thrown failure: the answer belongs under
  /// the form the operator is looking at, and they will try again in the same
  /// two fields.
  Future<void> signIn() async {
    if (state.isSubmitting) return;

    // Mark both fields dirty so an untouched field shows its error rather
    // than the form silently doing nothing when the button is pressed.
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);
    if (!Formz.validate([email, password])) {
      emit(state.copyWith(email: email, password: password));
      return;
    }

    emit(
      state.copyWith(
        status: FormzSubmissionStatus.inProgress,
        credentialsRejected: false,
        error: null,
      ),
    );

    try {
      final staff = await _staff.signIn(
        email: email.value,
        password: password.value,
      );
      if (isClosed) return;

      if (staff == null) {
        emit(
          state.copyWith(
            status: FormzSubmissionStatus.failure,
            credentialsRejected: true,
          ),
        );
        return;
      }

      emit(state.copyWith(status: FormzSubmissionStatus.success));
      await _auth.startSession(staff);
    } on AppException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(status: FormzSubmissionStatus.failure, error: error),
      );
    }
  }
}
