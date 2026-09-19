// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';

import 'package:formz/formz.dart';

enum PasswordValidationError { empty, tooShort, tooLong }

/// A validated password input for staff sign-in.
class Password extends FormzInput<String, PasswordValidationError> {
  const Password.pure() : super.pure('');
  const Password.dirty([super.value = '']) : super.dirty();

  static const int minLength = 8;

  /// bcrypt accepts at most 72 UTF-8 bytes — longer input throws in the
  /// hasher, past every guard, so the form rejects it first.
  static const int maxLengthBytes = 72;

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.empty;
    if (value.length < minLength) return PasswordValidationError.tooShort;
    if (utf8.encode(value).length > maxLengthBytes) {
      return PasswordValidationError.tooLong;
    }
    return null;
  }
}
