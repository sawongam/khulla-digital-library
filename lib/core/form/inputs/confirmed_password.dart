// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:formz/formz.dart';

enum ConfirmedPasswordValidationError { empty, mismatch }

/// The second password field on a form that sets a password.
///
/// Validates against the first one rather than against a rule of its own, so
/// the input is rebuilt with `ConfirmedPassword.dirty(password: ..., value:
/// ...)` whenever *either* field changes — a confirmation that matched the
/// old value must stop being valid the moment the first field is edited.
class ConfirmedPassword
    extends FormzInput<String, ConfirmedPasswordValidationError> {
  const ConfirmedPassword.pure({this.password = ''}) : super.pure('');

  const ConfirmedPassword.dirty({required this.password, String value = ''})
    : super.dirty(value);

  /// The value this field has to match.
  final String password;

  @override
  ConfirmedPasswordValidationError? validator(String value) {
    if (value.isEmpty) return ConfirmedPasswordValidationError.empty;
    if (value != password) return ConfirmedPasswordValidationError.mismatch;
    return null;
  }
}
