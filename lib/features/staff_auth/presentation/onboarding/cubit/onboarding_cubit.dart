// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/confirmed_password.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/full_name.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/core/form/inputs/required_text.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/core/security/recovery_code.dart';
import 'package:khulla/features/settings/domain/backup_repository.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_state.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';
import 'package:khulla/features/users/domain/user_role.dart';

/// First-run setup: name the library, pick its currency, create the
/// administrator who will run it, and issue recovery codes for that account.
///
/// Also the one place a backup can be adopted before any of that exists: a
/// fresh device takes on the backup's catalogue and staff instead of
/// creating its own, through [restoreFromBackup].
@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._library, this._staff, this._auth, this._backups)
    : super(const OnboardingState());

  final LibrarySettingsRepository _library;
  final StaffRepository _staff;
  final AuthCubit _auth;
  final BackupRepository _backups;

  void libraryNameChanged(String value) =>
      emit(state.copyWith(libraryName: RequiredText.dirty(value)));

  void currencyChanged(AppCurrency value) =>
      emit(state.copyWith(currency: value));

  void adminNameChanged(String value) =>
      emit(state.copyWith(adminName: FullName.dirty(value)));

  void emailChanged(String value) => emit(
    state.copyWith(email: Email.dirty(value), emailTaken: false, error: null),
  );

  /// Rebuilds the confirmation alongside the password, so a confirmation that
  /// matched the old value stops being valid the moment this field changes.
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

  void codesSavedChanged(bool value) => emit(state.copyWith(codesSaved: value));

  /// Moves to the account step once the library step holds.
  ///
  /// Marks the step's fields dirty first, so pressing *Continue* on an
  /// untouched form explains itself rather than doing nothing.
  void goToNextStep() {
    switch (state.step) {
      case OnboardingStep.library:
        final libraryName = RequiredText.dirty(state.libraryName.value);
        if (!libraryName.isValid) {
          emit(state.copyWith(libraryName: libraryName));
          return;
        }
        emit(state.copyWith(step: OnboardingStep.account, error: null));
      case OnboardingStep.account:
        goToRecoveryStep();
      case OnboardingStep.recovery:
        break;
    }
  }

  /// Validates the account step, issues recovery codes once, and shows them.
  ///
  /// Codes are generated here rather than at submit so the operator can copy
  /// or download them before anything is written. Closing the app on this
  /// step leaves the catalogue unset, and setup starts again.
  void goToRecoveryStep() {
    final adminName = FullName.dirty(state.adminName.value);
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);
    final confirmPassword = ConfirmedPassword.dirty(
      password: password.value,
      value: state.confirmPassword.value,
    );

    if (!Formz.validate([adminName, email, password, confirmPassword])) {
      emit(
        state.copyWith(
          adminName: adminName,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        adminName: adminName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        recoveryCodes: state.recoveryCodes.isEmpty
            ? RecoveryCode.generateSet()
            : state.recoveryCodes,
        step: OnboardingStep.recovery,
        error: null,
      ),
    );
  }

  void goToPreviousStep() => emit(
    state.copyWith(
      step: switch (state.step) {
        OnboardingStep.recovery => OnboardingStep.account,
        OnboardingStep.account ||
        OnboardingStep.library => OnboardingStep.library,
      },
      error: null,
    ),
  );

  /// Adopts a backup file instead of setting up a new library.
  ///
  /// Anything typed on the wizard is discarded: the catalogue, the staff
  /// accounts and the loan records all come from the file, and the operator
  /// signs in with one of that backup's accounts afterwards. Restarts the
  /// app on success and never returns to this screen.
  ///
  /// Returns false when the operator cancelled the file picker. Emits the
  /// failure into state *and* rethrows: a gesture asked for this, so the
  /// page answers it with a toast as well as the inline message.
  Future<bool> restoreFromBackup() async {
    if (state.isSubmitting) return false;

    emit(
      state.copyWith(
        status: FormzSubmissionStatus.inProgress,
        error: null,
      ),
    );
    try {
      final restored = await _backups.restoreBackup();
      if (isClosed) return restored;
      if (!restored) {
        emit(state.copyWith(status: FormzSubmissionStatus.initial));
      }
      return restored;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(
        state.copyWith(
          status: FormzSubmissionStatus.failure,
          error: error,
        ),
      );
      rethrow;
    }
  }

  /// Writes the library profile, the administrator, and the hashed recovery
  /// codes, then opens the session.
  ///
  /// The profile and staff writes are not one transaction, and that is
  /// survivable by design: the setup gate is the staff table, so a profile
  /// written without its administrator leaves the app on this screen, and the
  /// retry overwrites the profile row rather than adding a second. The reverse
  /// order would not be survivable — an administrator with no library profile
  /// would let the app into the shell with no currency set.
  ///
  /// Emits the failure into state *and* rethrows: a gesture asked for this,
  /// so the page answers it with a toast as well as the inline message.
  Future<void> completeSetup() async {
    if (state.isSubmitting) return;
    if (!state.codesSaved || state.recoveryCodes.isEmpty) return;

    emit(
      state.copyWith(
        status: FormzSubmissionStatus.inProgress,
        emailTaken: false,
        error: null,
      ),
    );

    try {
      await _library.saveProfile(
        LibraryProfile(
          name: state.libraryName.value,
          currency: state.currency,
          createdAt: DateTime.now(),
        ),
      );
      final administrator = await _staff.createStaff(
        name: state.adminName.value,
        email: state.email.value,
        password: state.password.value,
        role: UserRole.administrator,
        recoveryCodes: state.recoveryCodes,
      );
      if (isClosed) return;

      emit(state.copyWith(status: FormzSubmissionStatus.success));
      // Last, and only once both writes landed: this is what flips the router
      // over to the shell, so the screen must not move before the catalogue
      // has the rows behind it.
      await _auth.startSession(administrator);
    } on AppException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: FormzSubmissionStatus.failure,
          emailTaken: error is DuplicateRecordException,
          error: error,
        ),
      );
      rethrow;
    }
  }
}
