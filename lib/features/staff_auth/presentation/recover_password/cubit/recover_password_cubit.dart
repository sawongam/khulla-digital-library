// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/confirmed_password.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/core/form/inputs/required_text.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/recover_password/cubit/recover_password_state.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';

/// Resets the first administrator's password with a one-time recovery code.
@injectable
class RecoverPasswordCubit extends Cubit<RecoverPasswordState> {
  RecoverPasswordCubit(this._staff, this._auth)
    : super(const RecoverPasswordState());

  final StaffRepository _staff;
  final AuthCubit _auth;

  void emailChanged(String value) => emit(
    state.copyWith(
      email: Email.dirty(value),
      credentialsRejected: false,
      error: null,
    ),
  );

  void recoveryCodeChanged(String value) => emit(
    state.copyWith(
      recoveryCode: RequiredText.dirty(value),
      credentialsRejected: false,
      error: null,
    ),
  );

  void passwordChanged(String value) => emit(
    state.copyWith(
      password: Password.dirty(value),
      confirmPassword: state.confirmPassword.isPure
          ? ConfirmedPassword.pure(password: value)
          : ConfirmedPassword.dirty(
              password: value,
              value: state.confirmPassword.value,
            ),
      credentialsRejected: false,
      error: null,
    ),
  );

  void confirmPasswordChanged(String value) => emit(
    state.copyWith(
      confirmPassword: ConfirmedPassword.dirty(
        password: state.password.value,
        value: value,
      ),
      credentialsRejected: false,
      error: null,
    ),
  );

  /// Verifies a recovery code and, when it holds, writes the new password
  /// and opens the session.
  Future<void> resetPasswordWithRecoveryCode() async {
    if (state.isSubmitting) return;

    final email = Email.dirty(state.email.value);
    final recoveryCode = RequiredText.dirty(state.recoveryCode.value);
    final password = Password.dirty(state.password.value);
    final confirmPassword = ConfirmedPassword.dirty(
      password: password.value,
      value: state.confirmPassword.value,
    );
    if (!Formz.validate([email, recoveryCode, password, confirmPassword])) {
      emit(
        state.copyWith(
          email: email,
          recoveryCode: recoveryCode,
          password: password,
          confirmPassword: confirmPassword,
        ),
      );
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
      final staff = await _staff.resetPasswordWithRecoveryCode(
        email: email.value,
        recoveryCode: recoveryCode.value,
        newPassword: password.value,
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
