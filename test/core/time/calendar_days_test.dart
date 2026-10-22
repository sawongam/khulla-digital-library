// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/core/time/calendar_days.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';

/// Calendar-day arithmetic must not depend on the machine's time zone.
///
/// Every expectation here holds in any zone, but the dates are chosen across
/// the 2026 daylight-saving changes in Europe (29 March, 25 October) and
/// North America (8 March, 1 November), where 24-hour arithmetic used to
/// lose or gain a day. Run the suite with `TZ=America/New_York` or
/// `TZ=Europe/London` to exercise them.
void main() {
  group('daysBetween', () {
    test('counts the spring-forward day as a whole day', () {
      expect(daysBetween(DateTime(2026, 3, 8), DateTime(2026, 3, 9)), 1);
      expect(daysBetween(DateTime(2026, 3, 29), DateTime(2026, 3, 30)), 1);
    });

    test('counts a span across both changes exactly', () {
      expect(daysBetween(DateTime(2026, 3), DateTime(2026, 3, 20)), 19);
      expect(daysBetween(DateTime(2026), DateTime(2027)), 365);
    });

    test('ignores the time of day on either side', () {
      expect(
        daysBetween(DateTime(2026, 3, 8, 23, 59), DateTime(2026, 3, 9, 0, 1)),
        1,
      );
    });

    test('is negative when the second date is earlier', () {
      expect(daysBetween(DateTime(2026, 11, 2), DateTime(2026, 11)), -1);
    });
  });

  group('addCalendarDays', () {
    test('lands on local midnight of the right date across fall-back', () {
      expect(
        addCalendarDays(DateTime(2026, 10, 25), 14),
        DateTime(2026, 11, 8),
      );
      expect(addCalendarDays(DateTime(2026, 10, 31), 1), DateTime(2026, 11));
    });

    test('lands on the right date across spring-forward', () {
      expect(addCalendarDays(DateTime(2026, 3), 14), DateTime(2026, 3, 15));
    });

    test('rolls over month and year ends, and goes backwards', () {
      expect(addCalendarDays(DateTime(2026, 12, 25), 10), DateTime(2027, 1, 4));
      expect(addCalendarDays(DateTime(2026, 3), -1), DateTime(2026, 2, 28));
    });

    test('drops the time of day', () {
      expect(
        addCalendarDays(DateTime(2026, 6, 1, 17, 45), 2),
        DateTime(2026, 6, 3),
      );
    });
  });

  group('computeOverdueFine across a daylight-saving change', () {
    test('charges every day late, including the short one', () {
      final fine = computeOverdueFine(
        dueAt: DateTime(2026, 3),
        asOf: DateTime(2026, 3, 20),
        finePerDay: Money.major(5),
        graceDays: 0,
        maximumFine: Money.major(1000),
      );

      expect(fine, Money.major(95));
    });

    test('grace days are whole calendar days too', () {
      final fine = computeOverdueFine(
        dueAt: DateTime(2026, 3, 7),
        asOf: DateTime(2026, 3, 10),
        finePerDay: Money.major(5),
        graceDays: 2,
        maximumFine: Money.major(1000),
      );

      expect(fine, Money.major(5));
    });
  });
}
