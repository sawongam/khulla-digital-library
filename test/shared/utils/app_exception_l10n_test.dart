// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_error_reason_l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';

/// What the desk reads when a rule refuses an action.
void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    final l10n = lookupAppLocalizations(locale);

    group('in ${locale.languageCode}', () {
      test('every reason has its own sentence', () {
        final sentences = {
          for (final reason in AppErrorReason.values)
            reason: reason.localizedMessage(l10n),
        };

        for (final entry in sentences.entries) {
          expect(entry.value.trim(), isNotEmpty, reason: '${entry.key}');
          expect(
            entry.value,
            isNot(l10n.errorConflict),
            reason: '${entry.key} fell back to the generic conflict copy',
          );
        }
      });

      test('a reason wins over the generic copy for its type', () {
        const refused = ConflictException.because(
          AppErrorReason.borrowingLimitReached,
        );

        expect(
          refused.localizedMessage(l10n),
          l10n.errorReasonBorrowingLimitReached,
        );
        expect(
          const ConflictException().localizedMessage(l10n),
          l10n.errorConflict,
        );
      });
    });
  }

  test('the Nepali copy is translated, not the English left in place', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final nepali = lookupAppLocalizations(const Locale('ne'));

    for (final reason in AppErrorReason.values) {
      expect(
        reason.localizedMessage(nepali),
        isNot(reason.localizedMessage(english)),
        reason: '$reason',
      );
    }
  });
}
