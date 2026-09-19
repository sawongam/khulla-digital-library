// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/theme/app_language.dart';
import 'package:khulla_ui/khulla_ui.dart';

part 'theme_state.freezed.dart';

/// The device-level appearance and language choices: light or dark, which
/// brand the product is painted in, and which language it is drawn in. All
/// are read from storage at startup, so the app's first frame is already
/// the operator's.
@freezed
abstract class ThemeState with _$ThemeState {
  const factory ThemeState({
    @Default(ThemeMode.light) ThemeMode mode,
    @Default(AppBrandTheme.teal) AppBrandTheme brandTheme,
    Color? customSeed,
    @Default(AppLanguage.english) AppLanguage language,
  }) = _ThemeState;

  const ThemeState._();

  /// The ramp the theme is built from. A mixed color wins over the preset,
  /// which stays put underneath as what the row falls back to.
  AppBrand get brand => switch (customSeed) {
    final seed? => AppBrand.fromSeed(seed),
    _ => brandTheme.brand,
  };

  /// The color the ramp is built from, preset or mixed.
  Color get brandSeed => customSeed ?? brandTheme.seed;
}
