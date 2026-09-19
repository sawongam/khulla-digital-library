// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/confirmed_password.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/full_name.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/presentation/cubit/staff_form_state.dart';
import 'package:khulla/shared/models/load_status.dart';

/// The add/edit-account dialog and the reset-password dialog, one cubit for
/// all three (see [StaffFormMode]).
///
/// Page-scoped `@injectable`, matching `MemberFormCubit` — a fresh instance
/// per dialog, closed when it's dismissed.
@injectable
class StaffFormCubit extends Cubit<StaffFormState> {
  StaffFormCubit(this._staff, this._auth) : super(const StaffFormState());

  final StaffRepository _staff;
  final AuthCubit _auth;

  /// Loads the account being edited or reset. Leaves the form pure for
  /// [StaffFormMode.create], where there is nothing to load.
  Future<void> load({required StaffFormMode mode, String? staffId}) async {
    emit(state.copyWith(status: LoadStatus.loading, mode: mode, error: null));
    try {
      final existing = staffId == null
          ? null
          : await _staff.findStaffById(staffId);
      if (isClosed) return;
      // A new account starts pure so the form opens quiet — dirtying an
      // empty input would fail validation immediately and paint errors
      // before the desk has typed anything. `save()` re-dirties every
      // field, so submit-time validation is unaffected.
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          existing: existing,
          name: existing == null
              ? const FullName.pure()
              : FullName.dirty(existing.name),
          email: existing == null
              ? const Email.pure()
              : Email.dirty(existing.email),
          role: existing?.role ?? UserRole.librarian,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  void nameChanged(String value) =>
      emit(state.copyWith(name: FullName.dirty(value)));

  void emailChanged(String value) => emit(
    state.copyWith(email: Email.dirty(value), emailTaken: false, error: null),
  );

  void roleChanged(UserRole value) => emit(state.copyWith(role: value));

  void passwordChanged(String value) => emit(
    state.copyWith(
      password: Password.dirty(value),
      confirmPassword: state.confirmPassword.isPure
          ? ConfirmedPassword.pure(password: value)
          : ConfirmedPassword.dirty(
              password: value,
              value: state.confirmPassword.value,
            ),
    ),
  );

  void confirmPasswordChanged(String value) => emit(
    state.copyWith(
      confirmPassword: ConfirmedPassword.dirty(
        password: state.password.value,
        value: value,
      ),
    ),
  );

  /// Validates and saves the create/edit form. Returns null when validation
  /// failed — the field messages are already in state, there is nothing
  /// further to tell the caller. Emits the failure into state *and*
  /// rethrows on a repository error, same as `MemberFormCubit.saveMember`.
  Future<StaffMember?> save() async {
    final isCreating = state.mode == StaffFormMode.create;
    final name = FullName.dirty(state.name.value);
    final email = Email.dirty(state.email.value);
    final password = isCreating
        ? Password.dirty(state.password.value)
        : state.password;
    final confirmPassword = isCreating
        ? ConfirmedPassword.dirty(
            password: password.value,
            value: state.confirmPassword.value,
          )
        : state.confirmPassword;

    final valid = isCreating
        ? Formz.validate([name, email, password, confirmPassword])
        : Formz.validate([name, email]);

    if (!valid) {
      emit(
        state.copyWith(
          name: name,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
        ),
      );
      return null;
    }

    emit(
      state.copyWith(
        submission: FormzSubmissionStatus.inProgress,
        emailTaken: false,
        error: null,
      ),
    );
    // The edit and profile paths need a loaded record and a signed-in actor.
    // The dialogs show the load error instead of the form when loading failed,
    // but guard here too so a submit can never hit a null assertion.
    final existing = state.existing;
    final actingId = _auth.state.staff?.id;
    if (!isCreating && (existing == null || actingId == null)) {
      return null;
    }
    try {
      final saved = isCreating
          ? await _staff.createStaff(
              name: name.value,
              email: email.value,
              password: password.value,
              role: state.role,
            )
          : await _staff.updateStaff(
              id: existing!.id,
              name: name.value,
              email: email.value,
              role: state.mode == StaffFormMode.profile
                  ? existing.role
                  : state.role,
              actingStaffId: actingId!,
            );
      if (isClosed) return saved;
      if (saved.id == actingId) {
        _auth.updateStaff(saved);
      }
      emit(
        state.copyWith(
          submission: FormzSubmissionStatus.success,
          existing: saved,
        ),
      );
      return saved;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(
        state.copyWith(
          submission: FormzSubmissionStatus.failure,
          emailTaken: error is DuplicateRecordException,
          error: error,
        ),
      );
      rethrow;
    }
  }

  /// Validates and submits the reset-password form. `false` means validation
  /// failed and the messages are already in state.
  Future<bool> resetPassword() async {
    final password = Password.dirty(state.password.value);
    final confirmPassword = ConfirmedPassword.dirty(
      password: password.value,
      value: state.confirmPassword.value,
    );
    if (!Formz.validate([password, confirmPassword])) {
      emit(
        state.copyWith(password: password, confirmPassword: confirmPassword),
      );
      return false;
    }

    final existing = state.existing;
    if (existing == null) {
      return false;
    }

    emit(
      state.copyWith(submission: FormzSubmissionStatus.inProgress, error: null),
    );
    try {
      await _staff.adminResetPassword(
        id: existing.id,
        newPassword: password.value,
      );
      if (isClosed) return true;
      emit(state.copyWith(submission: FormzSubmissionStatus.success));
      return true;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(
        state.copyWith(submission: FormzSubmissionStatus.failure, error: error),
      );
      rethrow;
    }
  }
}
