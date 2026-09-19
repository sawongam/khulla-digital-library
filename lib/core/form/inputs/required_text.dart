// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:formz/formz.dart';

enum RequiredTextValidationError { empty }

/// A field that only has to be filled in - a title, a shelf location, a note.
///
/// Trims before validating so a value of spaces does not pass.
class RequiredText extends FormzInput<String, RequiredTextValidationError> {
  const RequiredText.pure() : super.pure('');
  const RequiredText.dirty([super.value = '']) : super.dirty();

  @override
  RequiredTextValidationError? validator(String value) =>
      value.trim().isEmpty ? RequiredTextValidationError.empty : null;
}
