// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Raw color literals for the design system.
///
/// This is the **only** hex boundary in the repo. Do not import this file
/// from outside `packages/khulla_ui`. Widgets read color through
/// [ThemeData.colorScheme] or `context.appColors`.
///
/// Every value here is traced to `docs/design-tokens.json`, which is itself
/// reverse-engineered from the SaaS the product shares a design language
/// with. Three ramps carry the whole system:
///
/// * **brand** - one deep teal, taken from `assets/images/logos/submark_logo.png`.
///   It is
///   the *only* saturated hue in the chrome. Destructive actions use the
///   separate [danger] red so an alarm never reads as brand.
/// * **ink** - a text ramp that inverts in dark mode. `ink100` is the
///   darkest ink in light mode and the lightest in dark. The one exception is
///   [ink700], which is a *line* color and does not invert.
/// * **neutral** - a fixed grey ramp that never inverts, for surfaces that
///   are deliberately light whatever the theme.
///
/// The tints that carry every hover, active and selected surface come from
/// [accent] at low alpha, not from the brand teal - compositing a light aqua
/// over white stays airy where tinting the deep teal turns muddy.
abstract final class AppPalette {
  // ── Brand ─────────────────────────────────────────────────────────────────

  /// The brand. Primary fill, active nav ink, focus ring, required-field
  /// marker.
  static const Color brand = Color(0xFF0A6A66);

  /// The hairline drawn on a filled brand button, at 70% alpha.
  static const Color brandButtonBorder = Color(0xFF07514E);

  /// The source of every brand tint. Never painted at full strength.
  static const Color accent = Color(0xFF4FB3AC);

  /// The palest brand wash, for a surface that must be opaque.
  static const Color brandTint = Color(0xFFE1F0EE);

  /// The faintest brand wash.
  static const Color brandTintFaint = Color(0xFFF7FCFB);

  /// Content on a solid [brand] fill.
  static const Color onBrand = Color(0xFFFFFFFF);

  /// The brand darkened, for emphasis ink and the deep end of a gradient.
  static const Color brandDeep = Color(0xFF04403D);

  // ── Brand seeds ───────────────────────────────────────────────────────────
  //
  // The alternative brands the operator can pick in Appearance. Each is only
  // the solid fill - `AppBrand.fromSeed` derives the rest of the ramp - so a
  // seed is the one hex a new choice needs. [brand] is the shipped default and
  // is the seed of `AppBrand.teal`, whose ramp is hand-tuned rather than
  // derived.

  /// Seed: indigo.
  static const Color brandSeedIndigo = Color(0xFF4338CA);

  /// Seed: a mid blue.
  static const Color brandSeedBlue = Color(0xFF1D4ED8);

  /// Seed: violet.
  static const Color brandSeedViolet = Color(0xFF6D28D9);

  /// Seed: a deep rose.
  static const Color brandSeedRose = Color(0xFFA61E4D);

  /// Seed: burnt amber.
  static const Color brandSeedAmber = Color(0xFFB45309);

  /// Seed: forest green.
  static const Color brandSeedForest = Color(0xFF15803D);

  /// Seed: graphite, for a library that wants no hue at all.
  static const Color brandSeedGraphite = Color(0xFF334155);

  // ── Spectrum ──────────────────────────────────────────────────────────────

  /// The six hue turns, as the gradient stops of a hue slider.
  ///
  /// Not brand colors and never painted as one: this is the raw spectrum a
  /// color picker's track is drawn from, and it lives here so the rule that
  /// hex literals stay in this file holds for the picker too.
  static const List<Color> hueStops = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  // ── Ink ramp, light ───────────────────────────────────────────────────────

  /// Primary text.
  static const Color ink100Light = Color(0xFF121212);

  /// Form labels, dialog titles.
  static const Color ink200Light = Color(0xFF292929);

  /// Sub-navigation text.
  static const Color ink300Light = Color(0xFF404040);

  /// Navigation link at rest, filter labels.
  static const Color ink400Light = Color(0xFF575757);

  /// Secondary and meta text, outline-button ink.
  static const Color ink500Light = Color(0xFF707070);

  /// Tertiary text.
  static const Color ink600Light = Color(0xFF8C8C8C);

  // ── Ink ramp, dark ────────────────────────────────────────────────────────

  /// Primary text on dark.
  static const Color ink100Dark = Color(0xFFFFFFFF);

  /// Labels and dialog titles on dark.
  static const Color ink200Dark = Color(0xFFF5F5F5);

  /// Sub-navigation text on dark.
  static const Color ink300Dark = Color(0xFFDEDEDE);

  /// Navigation link at rest on dark.
  static const Color ink400Dark = Color(0xFFC9C9C9);

  /// Secondary and meta text on dark.
  static const Color ink500Dark = Color(0xFFB5B5B5);

  /// Tertiary text on dark.
  static const Color ink600Dark = Color(0xFF9E9E9E);

  /// The line color: checkbox border, zebra base, sub-item connectors.
  ///
  /// The one rung of the ink ramp that does **not** invert - it is a rule,
  /// not an ink, and a rule reads the same weight in either theme.
  static const Color ink700 = Color(0xFFCED4DA);

  // ── Fixed neutrals ────────────────────────────────────────────────────────

  /// Pure white.
  static const Color white100 = Color(0xFFFFFFFF);

  /// The card fill in the primitive card variant - greyer than the page.
  static const Color white200 = Color(0xFFF5F5F5);

  /// Separators and muted fills.
  static const Color white300 = Color(0xFFDEDEDE);

  /// A step down from [white300].
  static const Color white400 = Color(0xFFC9C9C9);

  /// A step down again.
  static const Color white500 = Color(0xFFB5B5B5);

  /// Leading-icon color inside a field; the unchecked switch track at 50%.
  static const Color white600 = Color(0xFF9E9E9E);

  /// The secondary surface: secondary button, ghost hover, tab track.
  static const Color secondaryLight = Color(0xFFF2F4F7);

  /// Placeholders, captions, table-head ink, selection counts.
  static const Color mutedForegroundLight = Color(0xFF999999);

  /// The single hairline. Every border in the light theme is this color.
  static const Color borderLight = Color(0xFFEBE9F1);

  // ── Dark surfaces ─────────────────────────────────────────────────────────

  /// The dark page canvas.
  static const Color backgroundDark = Color(0xFF121212);

  /// Card, popover and chrome surface on dark.
  static const Color surfaceDark = Color(0xFF292929);

  /// Muted fill on dark.
  static const Color mutedDark = Color(0xFF404040);

  /// The dark hairline.
  static const Color borderDark = Color(0xFF333333);

  /// Ambient shadow. Both themes cast black; the alphas differ.
  static const Color shadow = Color(0xFF000000);

  // ── Status ────────────────────────────────────────────────────────────────

  /// Danger ink - overdue, lost, destructive. The one alarm color, kept
  /// distinct from [brand] so a delete never reads as a brand action.
  static const Color danger = Color(0xFFD92D20);

  /// Danger, one step deeper, for a border or a pressed fill.
  static const Color dangerStrong = Color(0xFFB42318);

  /// The palest danger wash, for a surface that must be opaque.
  static const Color dangerTint = Color(0xFFFEE4E2);

  /// Success ink - returned, available, active. Forest, not a lime pill.
  static const Color success = Color(0xFF2F6B4A);

  /// Success, one step deeper, for a border or a pressed fill.
  static const Color successStrong = Color(0xFF24573C);

  /// Warning ink - due soon, expiring.
  static const Color warning = Color(0xFFE08A00);

  /// Warning, one step lighter.
  static const Color warningSoftInk = Color(0xFFE68F3D);

  /// Info ink - reserved, on hold, queued. Slate, not electric cyan.
  static const Color info = Color(0xFF4A7388);

  /// Premium / highlight accent.
  static const Color premium = Color(0xFFFDB021);

  // ── Literals the source design system itself hard-codes ───────────────────
  //
  // These bypass the token ramps in the SaaS deliberately. They are carried
  // over verbatim rather than approximated from the ramps above.

  /// Skeleton fill. Flat, no shimmer.
  static const Color skeleton = Color(0xFFF1F5F9);

  /// Avatar fallback wash behind initials.
  static const Color avatarFallback = Color(0xFFE1E6FF);

  /// The success *button* fill, which is not the [success] token.
  static const Color buttonSuccess = Color(0xFF22C55E);

  /// The hairline on a filled success button, at 70% alpha.
  static const Color buttonSuccessBorder = Color(0xFF16A34A);

  /// Link-button ink.
  static const Color link = Color(0xFF1D4ED8);

  /// The grey a ripple spawns in on light-surfaced buttons.
  static const Color rippleNeutral = Color(0xFFD1D5DB);

  // ── Reading surfaces ──────────────────────────────────────────────────────

  /// Warm parchment for long-form reading surfaces. Theme-invariant.
  static const Color paper = Color(0xFFF7F1E6);

  /// The raised end of a [paper] gradient.
  static const Color paperElevated = Color(0xFFEFE8DA);

  /// Content on [paper].
  static const Color onPaper = Color(0xFF2B2620);
}
