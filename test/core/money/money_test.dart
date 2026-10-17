// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/core/money/money_format.dart';

void main() {
  // Every display test depends on the ambient format, so pin it back after
  // each one — a leaked currency would make failures land in the wrong test.
  tearDown(() => MoneyFormat.current = MoneyFormat.nepaliRupee);

  group('construction', () {
    test('major units round to the nearest minor unit', () {
      // 2.99 * 100 is 298.99999... in binary floating point; the round() in
      // Money.major is what keeps this from being 298.
      expect(Money.major(2.99).minorUnits, 299);
      expect(Money.major(0.005).minorUnits, 1);
      expect(Money.major(10).minorUnits, 1000);
    });

    test('a stored column value reads as minor units', () {
      // Typed, not a bare `null` literal: both toMoney() extensions accept
      // null, so only the static type picks between them.
      const num? missing = null;

      expect(4500.toMoney(), const Money(4500));
      expect(missing.toMoney(), Money.zero);
    });

    test('parse tolerates grouping, symbol and blank', () {
      expect(Money.parse('Rs 1,240.50'), const Money(124050));
      expect(Money.parse('  '), Money.zero);
      expect(Money.parse(null), Money.zero);
      expect(Money.parse('not a number'), Money.zero);
    });
  });

  group('arithmetic', () {
    test('adding a column of amounts is exact', () {
      // The case a double would lose: 0.1 + 0.2 != 0.3 in binary.
      final total = Money.sum([Money.major(0.1), Money.major(0.2)]);

      expect(total, Money.major(0.3));
      expect(total.minorUnits, 30);
    });

    test('sum of nothing is zero', () {
      expect(Money.sum(const []), Money.zero);
    });

    test('scaling takes a scalar, and a daily rate accrues exactly', () {
      const perDay = Money(250);

      expect(perDay * 7, const Money(1750));
      expect((perDay * 7).display(), 'Rs 17.50');
    });

    test('percent and discounted round to the nearest minor unit', () {
      expect(Money.major(200).percent(15), Money.major(30));
      expect(Money.major(200).discounted(15), Money.major(170));
      expect(const Money(333).percent(50), const Money(167));
    });

    test('ratioTo returns zero rather than dividing by zero', () {
      expect(const Money(500).ratioTo(Money.zero), 0);
      expect(const Money(500).ratioTo(const Money(1000)), 0.5);
    });

    test('comparison and ordering read off the underlying integer', () {
      final amounts = [const Money(300), const Money(100), const Money(200)]
        ..sort((a, b) => a.compareTo(b));

      expect(amounts, [const Money(100), const Money(200), const Money(300)]);
      expect(Money.min(const Money(100), const Money(200)), const Money(100));
      expect(Money.max(const Money(100), const Money(200)), const Money(200));
      expect(const Money(100) < const Money(200), isTrue);
    });

    test('a negative amount is a credit, and abs strips the sign', () {
      const credit = Money(-500);

      expect(credit.isNegative, isTrue);
      expect(credit.abs(), const Money(500));
      expect(-credit, const Money(500));
    });
  });

  group('formatting', () {
    test('whole amounts drop the decimals, partial ones keep both places', () {
      expect(const Money(25000).display(), 'Rs 250');
      expect(const Money(25050).display(), 'Rs 250.50');
      expect(const Money(25005).display(), 'Rs 250.05');
    });

    test('the default format groups South-Asian style', () {
      expect(Money.major(123456).display(), 'Rs 1,23,456');
    });

    test('display follows the active format', () {
      MoneyFormat.current = MoneyFormat(
        symbol: r'$',
        grouping: MoneyGrouping.western,
        separator: '',
      );

      expect(Money.major(123456).display(), r'$123,456');
    });

    test('an explicit format overrides the active one', () {
      final euro = MoneyFormat(
        symbol: '€',
        grouping: MoneyGrouping.western,
        symbolOnRight: true,
      );

      expect(Money.major(1234).display(euro), '1,234 €');
      expect(Money.major(1234).display(), 'Rs 1,234');
    });

    test('editable is blank at zero and ungrouped otherwise', () {
      expect(Money.zero.editable, '');
      expect(const Money(124050).editable, '1240.5');
      expect(const Money(25000).editable, '250');
    });

    test('a typed amount survives a round trip through a text field', () {
      const fine = Money(124050);

      expect(fine.editable.toMoney(), fine);
    });
  });

  group('validation', () {
    test('blank counts as valid, negative and nonsense do not', () {
      const String? unset = null;

      expect(''.isValidMoney, isTrue);
      expect(unset.isValidMoney, isTrue);
      expect('250.50'.isValidMoney, isTrue);
      expect('-5'.isValidMoney, isFalse);
      expect('..'.isValidMoney, isFalse);
    });
  });
}
