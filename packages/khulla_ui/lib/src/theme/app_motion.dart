// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_motion}
/// Durations, curves and gesture constants.
///
/// The rule of thumb the whole system follows: **150ms for color, 300ms for
/// size and position, 500ms only for a sheet opening, 600ms only for a
/// ripple.** Entrances ease out; things that move in place ease in and out.
/// Anything slower than this reads as sluggish in an operator tool where the
/// same screen is opened forty times a shift.
/// {@endtemplate}
class AppMotion extends ThemeExtension<AppMotion> {
  /// {@macro app_motion}
  const AppMotion({
    this.color = const Duration(milliseconds: 150),
    this.short = const Duration(milliseconds: 120),
    this.overlay = const Duration(milliseconds: 200),
    this.layout = const Duration(milliseconds: 300),
    this.long = const Duration(milliseconds: 320),
    this.sheetOpen = const Duration(milliseconds: 500),
    this.sheetClose = const Duration(milliseconds: 300),
    this.ripple = const Duration(milliseconds: 600),
    this.pulse = const Duration(milliseconds: 2000),
    this.pressScale = 0.95,
    this.overlayScale = 0.95,
    this.overlaySlide = 8,
  });

  /// A hover, a selection, a tint swap.
  final Duration color;

  /// Direct manipulation - a press, a drag, a value ticking under the finger.
  final Duration short;

  /// A menu, popover or dialog appearing.
  final Duration overlay;

  /// Anything that changes size or position: a rail expanding, a field's
  /// focus nudge, an accordion.
  final Duration layout;

  /// Substituting one piece of content for another - a count sliding, a
  /// total swapping. Slightly longer than [layout] so the incoming glyph
  /// can settle.
  final Duration long;

  /// A side sheet sliding in. The one deliberately slow move in the app.
  final Duration sheetOpen;

  /// A side sheet leaving. Dismissal is always faster than arrival.
  final Duration sheetClose;

  /// A button's ripple, from tap point to full bleed.
  final Duration ripple;

  /// One skeleton breath.
  final Duration pulse;

  /// How far a pressed control shrinks.
  final double pressScale;

  /// The scale an overlay enters from.
  final double overlayScale;

  /// How far an overlay slides in from its trigger's side, in px.
  final double overlaySlide;

  /// Layout and in-place movement.
  Curve get standard => Curves.easeInOut;

  /// Entrances: fast at the start, settling at the end.
  Curve get entrance => Curves.easeOut;

  /// The skeleton pulse, which spends longer near full opacity than a
  /// symmetric curve would.
  Curve get pulseCurve => const Cubic(0.4, 0, 0.6, 1);

  @override
  AppMotion copyWith({
    Duration? color,
    Duration? short,
    Duration? overlay,
    Duration? layout,
    Duration? long,
    Duration? sheetOpen,
    Duration? sheetClose,
    Duration? ripple,
    Duration? pulse,
    double? pressScale,
    double? overlayScale,
    double? overlaySlide,
  }) {
    return AppMotion(
      color: color ?? this.color,
      short: short ?? this.short,
      overlay: overlay ?? this.overlay,
      layout: layout ?? this.layout,
      long: long ?? this.long,
      sheetOpen: sheetOpen ?? this.sheetOpen,
      sheetClose: sheetClose ?? this.sheetClose,
      ripple: ripple ?? this.ripple,
      pulse: pulse ?? this.pulse,
      pressScale: pressScale ?? this.pressScale,
      overlayScale: overlayScale ?? this.overlayScale,
      overlaySlide: overlaySlide ?? this.overlaySlide,
    );
  }

  @override
  AppMotion lerp(AppMotion? other, double t) =>
      other is AppMotion && t >= 0.5 ? other : this;
}
