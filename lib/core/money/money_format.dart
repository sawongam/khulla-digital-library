// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:intl/intl.dart';

/// How digits are grouped in a formatted amount.
enum MoneyGrouping {
  /// Thousands, then every two digits: `1,23,456`. Nepal, India, Bangladesh.
  southAsian,

  /// Every three digits: `123,456`. Most of the rest of the world.
  western;

  /// `NumberFormat` pattern for a whole amount.
  String get wholePattern => this == southAsian ? '#,##,##0' : '#,##0';

  /// `NumberFormat` pattern for an amount carrying minor units.
  String get decimalPattern => this == southAsian ? '#,##,##0.00' : '#,##0.00';
}

/// How an amount is rendered: currency symbol, placement, and digit grouping.
///
/// Khulla is deployed by libraries in different countries, so the currency is
/// a setting rather than a constant. What is **not** configurable is the
/// minor-unit factor: every amount is stored as an integer number of
/// hundredths (see `kMinorUnitsPerMajor`), because changing that factor would
/// silently reinterpret every fine and fee already written to the database.
/// A currency with no minor unit simply never shows the decimals.
class MoneyFormat {
  /// Builds a currency format.
  MoneyFormat({
    required this.symbol,
    this.grouping = MoneyGrouping.southAsian,
    this.symbolOnRight = false,
    this.separator = ' ',
  });

  /// Nepali rupee — the default, and the currency Khulla was written for.
  static final MoneyFormat nepaliRupee = MoneyFormat(symbol: 'Rs');

  /// The format every `Money.display()` uses unless handed an override.
  ///
  /// Set once during `bootstrap` from the library's settings, before the first
  /// frame. Changing it later is allowed — a settings screen switching
  /// currency — but nothing rebuilds on its own: the screen that changes it
  /// has to trigger a rebuild of anything showing an amount.
  static MoneyFormat current = nepaliRupee;

  /// The currency symbol, e.g. `Rs`, `₹`, `$`.
  final String symbol;

  /// How digits are grouped.
  final MoneyGrouping grouping;

  /// Whether [symbol] follows the number instead of preceding it.
  final bool symbolOnRight;

  /// Placed between the symbol and the number.
  final String separator;

  /// Grouped whole amount: `1,23,456`.
  ///
  /// Pinned to `en` so a locale change can never swap the digit set out from
  /// under an amount — a fine has to be legible to whoever is reading the
  /// screen and to whoever audits the till.
  late final NumberFormat _whole = NumberFormat(grouping.wholePattern, 'en');

  /// Grouped amount carrying minor units: `1,23,456.78`. Always both places —
  /// `1,240.5` reads as a typo where `1,240.50` reads as money.
  late final NumberFormat _decimal = NumberFormat(
    grouping.decimalPattern,
    'en',
  );

  /// Ungrouped amount for seeding a text field: `1234.56`, `250`.
  late final NumberFormat _plain = NumberFormat('#0.##', 'en');

  /// [major] grouped, with no symbol. Whole amounts drop the decimals.
  String grouped(double major, {required bool isWhole}) =>
      (isWhole ? _whole : _decimal).format(major);

  /// [major] ungrouped, for an editable field.
  String plain(double major) => _plain.format(major);

  /// [amount] with the symbol attached on the configured side.
  String withSymbol(String amount) =>
      symbolOnRight ? '$amount$separator$symbol' : '$symbol$separator$amount';
}
