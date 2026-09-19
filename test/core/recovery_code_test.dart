// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/security/recovery_code.dart';

void main() {
  group('RecoveryCode', () {
    test(
      'generateSet returns the configured number of unique formatted codes',
      () {
        final codes = RecoveryCode.generateSet();
        expect(codes, hasLength(RecoveryCode.setSize));
        expect(codes.toSet(), hasLength(RecoveryCode.setSize));
        for (final code in codes) {
          expect(
            code,
            matches(
              RegExp(r'^[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}$'),
            ),
          );
        }
      },
    );

    test('normalize strips separators and maps look-alike letters', () {
      expect(RecoveryCode.normalize('7k2m 9qwp-4xnh b6rt'), '7K2M9QWP4XNHB6RT');
      expect(RecoveryCode.normalize('OILU'), '011V');
    });

    test('hash is stable for equivalent typed forms', () {
      const formatted = '7K2M-9QWP-4XNH-B6RT';
      expect(
        RecoveryCode.hash(formatted),
        RecoveryCode.hash('7k2m9qwp4xnhb6rt'),
      );
      expect(
        RecoveryCode.matches(
          '7k2m-9qwp-4xnh-b6rt',
          RecoveryCode.hash(formatted),
        ),
        isTrue,
      );
      expect(
        RecoveryCode.matches(
          'AAAA-AAAA-AAAA-AAAA',
          RecoveryCode.hash(formatted),
        ),
        isFalse,
      );
    });
  });
}
