// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:formz/formz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/confirmed_password.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/full_name.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/core/form/inputs/required_text.dart';
import 'package:khulla/core/money/currency.dart';

part 'onboarding_state.freezed.dart';

/// What first-run setup has to ask for, in order.
///
/// Library details and the administrator, then the recovery codes that are
/// the only way back in if that administrator forgets the password. Branch,
/// opening hours and loan rules have defaults and are edited under Settings.
enum OnboardingStep {
  /// What the library is called, and what it charges in.
  library,

  /// The administrator account that will run it.
  account,

  /// One-time codes to reset the administrator password offline.
  recovery;

  bool get isFirst => this == OnboardingStep.library;
  bool get isLast => this == OnboardingStep.recovery;

  /// One-based position, for "Step 1 of 3".
  int get position => index + 1;
}

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(OnboardingStep.library) OnboardingStep step,
    @Default(RequiredText.pure()) RequiredText libraryName,
    @Default(AppCurrency.npr) AppCurrency currency,
    @Default(FullName.pure()) FullName adminName,
    @Default(Email.pure()) Email email,
    @Default(Password.pure()) Password password,
    @Default(ConfirmedPassword.pure()) ConfirmedPassword confirmPassword,
    @Default(<String>[]) List<String> recoveryCodes,
    @Default(false) bool codesSaved,
    @Default(FormzSubmissionStatus.initial) FormzSubmissionStatus status,

    /// Set when the address is already held by an account. On a fresh
    /// catalogue this is all but impossible; on a restored one it is not.
    @Default(false) bool emailTaken,
    AppException? error,
  }) = _OnboardingState;

  const OnboardingState._();

  /// How many steps the wizard has. Read by the progress line so adding a
  /// step does not mean editing a hard-coded "of 3".
  static int get stepCount => OnboardingStep.values.length;

  bool get isLibraryStepValid => libraryName.isValid;

  bool get isAccountStepValid =>
      Formz.validate([adminName, email, password, confirmPassword]);

  /// Whether the button at the foot of the current step is enabled.
  bool get canAdvance => switch (step) {
    OnboardingStep.library => isLibraryStepValid,
    OnboardingStep.account => isAccountStepValid,
    OnboardingStep.recovery => codesSaved && recoveryCodes.isNotEmpty,
  };

  bool get isSubmitting => status.isInProgress;
}
