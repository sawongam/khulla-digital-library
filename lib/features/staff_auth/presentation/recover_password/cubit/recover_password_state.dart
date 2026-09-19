// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:formz/formz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/confirmed_password.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/core/form/inputs/required_text.dart';

part 'recover_password_state.freezed.dart';

@freezed
abstract class RecoverPasswordState with _$RecoverPasswordState {
  const factory RecoverPasswordState({
    @Default(Email.pure()) Email email,
    @Default(RequiredText.pure()) RequiredText recoveryCode,
    @Default(Password.pure()) Password password,
    @Default(ConfirmedPassword.pure()) ConfirmedPassword confirmPassword,
    @Default(FormzSubmissionStatus.initial) FormzSubmissionStatus status,
    @Default(false) bool credentialsRejected,
    AppException? error,
  }) = _RecoverPasswordState;

  const RecoverPasswordState._();

  bool get isValid =>
      Formz.validate([email, recoveryCode, password, confirmPassword]);

  bool get isSubmitting => status.isInProgress;
}
