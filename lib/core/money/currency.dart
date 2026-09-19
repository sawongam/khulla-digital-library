// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:country_phone_kit/country_phone_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:khulla/core/money/money_format.dart';

/// The currency a library charges fines and fees in.
///
/// [code], [name] and [symbol] are what the catalogue stores. The picker is
/// seeded from [Currencies], but amounts on screen read the saved symbol — not
/// a live lookup.
@immutable
final class AppCurrency implements Comparable<AppCurrency> {
  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  factory AppCurrency.fromCountryCurrency(CountryCurrency currency) =>
      AppCurrency(
        code: currency.code,
        name: currency.name,
        symbol: currency.symbol,
      );

  /// ISO-4217 alpha code, e.g. `NPR`, `EUR`, `USD`.
  final String code;

  /// English name, e.g. `Nepalese rupee`.
  final String name;

  /// The symbol as written locally, e.g. `Rs`, `€`.
  final String symbol;

  /// Every currency the picker can offer, sorted by code.
  static List<AppCurrency> get values => Currencies.all
      .map(AppCurrency.fromCountryCurrency)
      .toList(growable: false);

  static const npr = AppCurrency(
    code: 'NPR',
    name: 'Nepalese rupee',
    symbol: 'Rs',
  );

  /// How amounts are rendered in this currency: symbol, side, and grouping.
  ///
  /// What this never decides is the storage unit — every amount is an integer
  /// number of hundredths whatever the currency. See `Money`.
  MoneyFormat get format => MoneyFormat(symbol: symbol);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCurrency &&
          other.code == code &&
          other.name == name &&
          other.symbol == symbol;

  @override
  int get hashCode => Object.hash(code, name, symbol);

  @override
  int compareTo(AppCurrency other) => code.compareTo(other.code);

  @override
  String toString() => 'AppCurrency($code)';
}
