// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/features/updates/domain/update_rules.dart';

/// When a release counts as newer, and when the daily check is due.
void main() {
  group('isNewerRelease', () {
    bool newer(String running, int? build, String release, int releaseBuild) =>
        isNewerRelease(
          runningVersion: running,
          runningBuild: build,
          releaseVersion: release,
          releaseBuild: releaseBuild,
        );

    test('the build number decides when the running build reports one', () {
      expect(newer('1.1.2', 6, '1.1.3', 7), isTrue);
      expect(newer('1.1.2', 6, '1.1.2', 6), isFalse);
      // A dev build ahead of the last release is not offered a downgrade.
      expect(newer('1.2.0', 8, '1.1.3', 7), isFalse);
    });

    test('falls back to the dotted version without a build number', () {
      expect(newer('1.9.0', null, '1.10.0', 1), isTrue);
      expect(newer('1.10.0', null, '1.9.0', 1), isFalse);
      expect(newer('1.1.2', null, '1.1.2', 1), isFalse);
      expect(newer('1.1.2-dev.abc1234', null, '1.1.3', 1), isTrue);
    });

    test('a running version that cannot be read is never offered one', () {
      expect(newer('x.x.x', null, '9.9.9', 99), isFalse);
    });
  });

  group('isUpdateCheckDue', () {
    final now = DateTime(2026, 11, 17, 9);

    test('due on first launch and a day after the last check', () {
      expect(isUpdateCheckDue(lastCheckedAt: null, now: now), isTrue);
      expect(
        isUpdateCheckDue(
          lastCheckedAt: now.subtract(const Duration(hours: 24)),
          now: now,
        ),
        isTrue,
      );
    });

    test('not due again within the day', () {
      expect(
        isUpdateCheckDue(
          lastCheckedAt: now.subtract(const Duration(hours: 23)),
          now: now,
        ),
        isFalse,
      );
    });

    test('due when the clock has been wound back past the last check', () {
      expect(
        isUpdateCheckDue(
          lastCheckedAt: now.add(const Duration(days: 30)),
          now: now,
        ),
        isTrue,
      );
    });
  });
}
