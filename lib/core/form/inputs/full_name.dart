// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:formz/formz.dart';

enum FullNameValidationError { empty, tooShort }

/// A validated full-name input used for member and staff records.
class FullName extends FormzInput<String, FullNameValidationError> {
  const FullName.pure() : super.pure('');
  const FullName.dirty([super.value = '']) : super.dirty();

  @override
  FullNameValidationError? validator(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return FullNameValidationError.empty;
    if (trimmed.length < 2) return FullNameValidationError.tooShort;
    return null;
  }
}
