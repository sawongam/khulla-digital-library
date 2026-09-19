// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:formz/formz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/password.dart';

part 'sign_in_state.freezed.dart';

@freezed
abstract class SignInState with _$SignInState {
  const factory SignInState({
    @Default(Email.pure()) Email email,
    @Default(Password.pure()) Password password,
    @Default(FormzSubmissionStatus.initial) FormzSubmissionStatus status,

    /// Set when the catalogue answered but the address or password was wrong.
    /// Distinct from [error], which means the catalogue could not be read at
    /// all - one is the operator's problem, the other is the machine's.
    @Default(false) bool credentialsRejected,

    /// Whether unused recovery codes exist, so the recover link is worth
    /// showing. False when none remain.
    @Default(false) bool canRecoverPassword,

    /// Whether [canRecoverPassword] has been read from the catalogue. Until
    /// then the sign-in form does not show recovery copy either way.
    @Default(false) bool recoveryAvailabilityLoaded,
    AppException? error,
  }) = _SignInState;

  const SignInState._();

  /// Whether the form may be submitted. Both fields have to be valid, which
  /// on a sign-in form only rules out the obviously incomplete - the real
  /// answer comes from the catalogue.
  bool get isValid => Formz.validate([email, password]);

  bool get isSubmitting => status.isInProgress;
}
