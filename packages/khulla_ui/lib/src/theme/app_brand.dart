// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';
import 'package:khulla_ui/src/theme/app_palette.dart';

/// The brand ramp the theme is colored from.
///
/// Six roles, not one color: the solid fill, the ink that sits on it, the
/// hover/pressed step, the deep emphasis ink, the pale opaque wash, and the
/// [accent] every hover, active and selected surface composites from. They
/// travel together so the whole product moves as one when the brand changes -
/// a primary button and the navigation rail cannot end up different hues.
///
/// [teal] is the shipped ramp and keeps the hand-tuned constants from the
/// palette. [AppBrand.fromSeed] derives the same six roles from an arbitrary
/// color, working in HSL so the hue survives and only lightness and saturation
/// move.
@immutable
class AppBrand {
  /// A ramp with every role given explicitly.
  const AppBrand({
    required this.seed,
    required this.onBrand,
    required this.accent,
    required this.tint,
    required this.tintFaint,
    required this.deep,
    required this.strong,
  });

  /// Derives the ramp from [seed], the solid fill.
  ///
  /// Saturation is pulled back for [accent] because that color is painted at
  /// 3–30% alpha over a surface: a fully saturated tint reads as a stain.
  factory AppBrand.fromSeed(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    final accent = hsl
        .withSaturation((hsl.saturation * 0.75).clamp(0.2, 0.7))
        .withLightness(0.55)
        .toColor();

    return AppBrand(
      seed: seed,
      // A pale seed needs dark ink on it; anything else takes white.
      onBrand: seed.computeLuminance() > 0.45
          ? AppPalette.ink100Light
          : AppPalette.white100,
      accent: accent,
      tint: _wash(accent, 0.18),
      tintFaint: _wash(accent, 0.05),
      deep: hsl.withLightness(hsl.lightness * 0.55).toColor(),
      strong: hsl.withLightness(hsl.lightness * 0.78).toColor(),
    );
  }

  /// The shipped ramp: the deep teal taken from the submark logo.
  static const AppBrand teal = AppBrand(
    seed: AppPalette.brand,
    onBrand: AppPalette.onBrand,
    accent: AppPalette.accent,
    tint: AppPalette.brandTint,
    tintFaint: AppPalette.brandTintFaint,
    deep: AppPalette.brandDeep,
    strong: AppPalette.brandButtonBorder,
  );

  /// Primary fill, active nav ink, focus ring, required-field marker.
  final Color seed;

  /// Content on a solid [seed] fill.
  final Color onBrand;

  /// The tint source. Never painted at full strength.
  final Color accent;

  /// The palest wash, for a surface that must be opaque.
  final Color tint;

  /// The faintest wash.
  final Color tintFaint;

  /// The brand darkened, for emphasis ink and the deep end of a gradient.
  final Color deep;

  /// Hovered / pressed brand.
  final Color strong;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBrand &&
          other.seed == seed &&
          other.onBrand == onBrand &&
          other.accent == accent &&
          other.tint == tint &&
          other.tintFaint == tintFaint &&
          other.deep == deep &&
          other.strong == strong;

  @override
  int get hashCode =>
      Object.hash(seed, onBrand, accent, tint, tintFaint, deep, strong);
}

/// A wash flattened against white, so a badge drawn over a zebra row or a
/// tinted panel keeps the same color it has on the page.
Color _wash(Color hue, double alpha) =>
    Color.alphaBlend(hue.withValues(alpha: alpha), AppPalette.white100);
