// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money_format.dart';

/// Minor units in one major unit - paisa in a rupee, cents in a dollar.
///
/// Fixed, not a setting. Every amount in the catalogue is stored as an integer
/// of these, so changing the factor would reinterpret every fine and fee
/// already written to the database. The currency *symbol* and grouping are
/// configurable ([MoneyFormat]); the storage unit is not.
const int kMinorUnitsPerMajor = 100;

/// An amount of money, held in **minor units**.
///
/// Every calculation stays in minor units, so the arithmetic is exact integer
/// math and never accumulates the drift a `double` rupee amount would. Only
/// display divides by [kMinorUnitsPerMajor].
///
/// This is a zero-cost extension type over `int`: it allocates nothing, and it
/// gets value equality and hashing from the underlying int for free - which is
/// also why it stores and reads back from a SQLite `INTEGER` column directly.
///
/// The database edge is declared once, not remembered per call: a column
/// written `integer().map(const MoneyConverter())` hands back a [Money], and
/// `MoneyConverter` is the only place `minorUnits` is unwrapped for storage.
///
/// The two edges left are:
///
/// - **user-typed text** - [MoneyFromText.toMoney] / [Money.parse], which
///   multiply by [kMinorUnitsPerMajor], and [editable] on the way back;
/// - **a raw row** - `row.read<int>('amount').toMoney()` for the rare
///   `customSelect` that bypasses the generated classes (see [MoneyFromNum]).
///
/// ```dart
/// final rate  = fine.perDay;                       // Money, via the converter
/// final owed  = rate * loan.daysOverdue;           // exact, still minor units
/// Text(owed.display());                            // 'Rs 45'
/// ```
///
/// **Never interpolate a [Money] directly.** `'$owed'` prints the raw minor
/// units (`4500`), because an extension type inherits `int.toString`. Every
/// user-facing string goes through [display] or [editable].
extension type const Money(int minorUnits) {
  /// Builds [Money] from a major-unit amount - user input, or a literal.
  ///
  /// Rounds to the nearest minor unit, which also absorbs the
  /// binary-floating-point error in `2.99 * 100`.
  Money.major(num amount) : minorUnits = (amount * kMinorUnitsPerMajor).round();

  /// Parses major-unit text into [Money], tolerating the shapes a user or a
  /// formatter can produce: grouping commas, spaces, and a leading symbol.
  ///
  /// Anything unparseable - including null and blank - is [zero]. Callers that
  /// need to tell "empty" from "nonsense" apart validate with
  /// [MoneyFromText.isValidMoney] first.
  factory Money.parse(String? text) => Money.major(
    num.tryParse(_stripped(text)) ?? 0,
  );

  /// No money at all. The identity for [operator +] and the default for every
  /// optional amount.
  static const Money zero = Money(0);

  /// Total of [amounts], or [zero] when empty.
  static Money sum(Iterable<Money> amounts) =>
      amounts.fold(zero, (total, amount) => total + amount);

  /// The smaller of [a] and [b].
  static Money min(Money a, Money b) => a <= b ? a : b;

  /// The larger of [a] and [b].
  static Money max(Money a, Money b) => a >= b ? a : b;

  /// The amount in major units.
  ///
  /// Display and text-field seeding only - never feed this back into a
  /// calculation, or the exactness the integer representation buys is gone.
  double get major => minorUnits / kMinorUnitsPerMajor;

  /// Whether this amount is exactly nothing.
  bool get isZero => minorUnits == 0;

  /// Whether this amount is anything other than nothing.
  bool get isNotZero => minorUnits != 0;

  /// Whether this amount is below zero - a credit on a member's account.
  bool get isNegative => minorUnits < 0;

  /// Whether this amount is above zero.
  bool get isPositive => minorUnits > 0;

  /// Whether this amount has no fractional part to show.
  bool get isWhole => minorUnits % kMinorUnitsPerMajor == 0;

  /// Sum of two amounts.
  Money operator +(Money other) => Money(minorUnits + other.minorUnits);

  /// Difference of two amounts.
  Money operator -(Money other) => Money(minorUnits - other.minorUnits);

  /// This amount with its sign flipped.
  Money operator -() => Money(-minorUnits);

  /// Scales by a plain number - a day count, a copy count, a multiplier.
  ///
  /// The operand is a scalar, not a [Money]: minor units times minor units is
  /// not an amount of money, and letting it typecheck is how a total ends up
  /// 100x off.
  Money operator *(num factor) => Money((minorUnits * factor).round());

  /// Splits by a plain number, rounding to the nearest minor unit.
  Money operator /(num divisor) => Money((minorUnits / divisor).round());

  /// Whether this amount is less than [other].
  bool operator <(Money other) => minorUnits < other.minorUnits;

  /// Whether this amount is at most [other].
  bool operator <=(Money other) => minorUnits <= other.minorUnits;

  /// Whether this amount is greater than [other].
  bool operator >(Money other) => minorUnits > other.minorUnits;

  /// Whether this amount is at least [other].
  bool operator >=(Money other) => minorUnits >= other.minorUnits;

  /// Orders two amounts, for `sort`.
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  /// This amount without its sign.
  Money abs() => Money(minorUnits.abs());

  /// [rate] percent *of* this amount - `Money.major(200).percent(15)` is
  /// `Rs 30`. For a surcharge, add the result back.
  Money percent(num rate) => Money((minorUnits * rate / 100).round());

  /// This amount with [rate] percent taken off - a waiver on a fine.
  Money discounted(num rate) => this - percent(rate);

  /// What fraction of [other] this amount is, for progress bars and trends.
  /// `0` when [other] is [zero], so a fresh ledger cannot divide by zero.
  double ratioTo(Money other) =>
      other.isZero ? 0 : minorUnits / other.minorUnits;

  /// Amount with the currency symbol, the default for anything a user reads:
  /// `Rs 1,23,456.78`.
  ///
  /// Pass [format] only for the rare call site that must render a currency
  /// other than the library's - an imported record, a printed receipt in a
  /// donor's currency.
  String display([MoneyFormat? format]) {
    final active = format ?? MoneyFormat.current;
    return active.withSymbol(active.grouped(major, isWhole: isWhole));
  }

  /// Plain, ungrouped major units for seeding an editable field, blank when
  /// [zero] so an empty amount box does not read `0`.
  String get editable => isZero ? '' : MoneyFormat.current.plain(major);
}

/// Everything [Money.parse] tolerates around the number itself.
String _stripped(String? text) =>
    (text ?? '').replaceAll(RegExp(r'[^0-9.\-]'), '');

/// Lifts a stored amount - minor units as `num`, straight off a database row -
/// into [Money].
///
/// Declared on the nullable type so one name covers both: a missing amount is
/// [Money.zero], which is what every screen wants to render.
///
/// A **bare `null` literal** is the one call that will not compile - it
/// matches this extension and [MoneyFromText] equally. Give the receiver a
/// type (`const num? unset = null;`) rather than reaching for a cast; in real
/// code the value always has one already.
extension MoneyFromNum on num? {
  /// This value read as minor units.
  Money toMoney() => Money((this ?? 0).round());
}

/// Reads money a user typed as major-unit text (form controllers, filters).
extension MoneyFromText on String? {
  /// This text parsed into [Money]; [Money.zero] when blank or invalid.
  Money toMoney() => Money.parse(this);

  /// `true` when blank - treated as zero - or a non-negative amount.
  bool get isValidMoney {
    final text = _stripped(this);
    if (text.isEmpty) return true;
    final value = num.tryParse(text);
    return value != null && value >= 0;
  }
}
