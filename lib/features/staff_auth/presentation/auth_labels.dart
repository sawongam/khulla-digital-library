// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/form/inputs/confirmed_password.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/full_name.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/core/form/inputs/required_text.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/l10n/l10n.dart';

/// Localized messages for the inputs the sign-in and onboarding forms use.
///
/// A field shows its message only once it has been edited: an error under a
/// form nobody has typed in yet reads as an accusation, not as help. That is
/// what [messageFor] encodes — a pure input has nothing to say.
extension EmailErrorX on Email {
  String? messageFor(AppLocalizations l10n) => isPure || isValid
      ? null
      : switch (error!) {
          EmailValidationError.empty => l10n.validationEmailRequired,
          EmailValidationError.invalid => l10n.validationEmailInvalid,
        };
}

extension PasswordErrorX on Password {
  String? messageFor(AppLocalizations l10n) => isPure || isValid
      ? null
      : switch (error!) {
          PasswordValidationError.empty => l10n.validationPasswordRequired,
          PasswordValidationError.tooShort => l10n.validationPasswordTooShort(
            Password.minLength,
          ),
          PasswordValidationError.tooLong => l10n.validationPasswordTooLong(
            Password.maxLengthBytes,
          ),
        };
}

extension ConfirmedPasswordErrorX on ConfirmedPassword {
  String? messageFor(AppLocalizations l10n) => isPure || isValid
      ? null
      : switch (error!) {
          ConfirmedPasswordValidationError.empty =>
            l10n.validationConfirmPasswordRequired,
          ConfirmedPasswordValidationError.mismatch =>
            l10n.validationPasswordsDoNotMatch,
        };
}

extension FullNameErrorX on FullName {
  String? messageFor(AppLocalizations l10n) => isPure || isValid
      ? null
      : switch (error!) {
          FullNameValidationError.empty => l10n.validationNameRequired,
          FullNameValidationError.tooShort => l10n.validationNameTooShort,
        };
}

extension RequiredTextErrorX on RequiredText {
  String? messageFor(AppLocalizations l10n) =>
      isPure || isValid ? null : l10n.validationFieldRequired;
}

extension AppCurrencyLabelX on AppCurrency {
  /// The currency's name, with its code, as the picker shows it.
  String label(AppLocalizations l10n) => switch (code) {
    'NPR' => l10n.currencyNpr,
    'INR' => l10n.currencyInr,
    'USD' => l10n.currencyUsd,
    'EUR' => l10n.currencyEur,
    'GBP' => l10n.currencyGbp,
    _ => '$name ($code)',
  };
}
