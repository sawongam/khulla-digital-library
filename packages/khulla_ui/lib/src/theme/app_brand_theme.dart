// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';
import 'package:khulla_ui/src/theme/app_palette.dart';

/// The brands an operator can choose between.
///
/// A closed set rather than a free color picker: every ramp here has been
/// looked at against the ink, the hairlines and the status colors, and a
/// picker would happily hand the product a yellow primary with white text on
/// it. Adding one is a seed in the palette plus an entry here - the rest of
/// the ramp is derived by [AppBrand.fromSeed].
///
/// The name is not the label. This enum carries no user-facing text; the app
/// resolves each value to a localized name.
enum AppBrandTheme {
  /// The shipped brand.
  teal(AppPalette.brand),

  /// Indigo.
  indigo(AppPalette.brandSeedIndigo),

  /// A mid blue.
  blue(AppPalette.brandSeedBlue),

  /// Violet.
  violet(AppPalette.brandSeedViolet),

  /// A deep rose.
  rose(AppPalette.brandSeedRose),

  /// Burnt amber.
  amber(AppPalette.brandSeedAmber),

  /// Forest green.
  forest(AppPalette.brandSeedForest),

  /// Graphite, for a library that wants no hue at all.
  graphite(AppPalette.brandSeedGraphite);

  AppBrandTheme(this.seed);

  /// The solid fill this choice paints with, and the swatch shown for it.
  final Color seed;

  /// The full ramp. [teal] keeps its hand-tuned constants; the rest derive.
  AppBrand get brand =>
      this == AppBrandTheme.teal ? AppBrand.teal : AppBrand.fromSeed(seed);
}
