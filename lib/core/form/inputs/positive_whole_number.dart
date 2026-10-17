// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:formz/formz.dart';

enum PositiveWholeNumberValidationError { empty, invalid }

/// A whole number of one or more, typed as text - the next value in a
/// barcode sequence, a count of copies.
///
/// Held as the text the operator typed rather than as an `int`, so a field
/// mid-edit ("1", "", "12") round-trips exactly; [number] is the parsed
/// value once [isValid].
class PositiveWholeNumber
    extends FormzInput<String, PositiveWholeNumberValidationError> {
  const PositiveWholeNumber.pure([super.value = '']) : super.pure();
  const PositiveWholeNumber.dirty([super.value = '']) : super.dirty();

  /// The parsed value, or null when the text is not a whole number.
  int? get number => int.tryParse(value.trim());

  @override
  PositiveWholeNumberValidationError? validator(String value) {
    if (value.trim().isEmpty) return PositiveWholeNumberValidationError.empty;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1) {
      return PositiveWholeNumberValidationError.invalid;
    }
    return null;
  }
}
