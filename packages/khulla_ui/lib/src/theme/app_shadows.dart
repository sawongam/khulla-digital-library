// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';
import 'package:khulla_ui/src/theme/app_palette.dart';

/// Elevation, as the three shadows this product actually uses.
///
/// Material's `elevation` numbers are not reachable from a token, and an
/// `elevation: 2` on one widget rarely matches an `elevation: 2` on another
/// once surface tint is involved. These are plain [BoxShadow] lists instead,
/// so a card, a menu and a sheet can be given the same depth by name.
///
/// The scale is deliberately shallow - the largest is a 15px blur at 10%
/// black. Depth here comes from the hairline; the shadow only stops a white
/// surface from cutting out of the canvas. Material's default elevation
/// shadows are several times darker and will make this UI look like a
/// different product, so do not substitute them.
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.card,
    required this.raised,
    required this.overlay,
  });

  /// The light scale.
  factory AppShadows.light() => AppShadows(
    card: _card(0.05),
    raised: _raised(0.1),
    overlay: _overlay(0.1),
  );

  /// The dark scale. A shadow is nearly invisible on a dark canvas, so the
  /// same three roles are carried by the same geometry at a heavier alpha.
  factory AppShadows.dark() => AppShadows(
    card: _card(0.3),
    raised: _raised(0.45),
    overlay: _overlay(0.55),
  );

  /// Anything resting on the canvas: a card, a button, a pinned table header.
  final List<BoxShadow> card;

  /// Anything floating just above the page: a menu, a popover, a tooltip.
  final List<BoxShadow> raised;

  /// Anything the page is behind: a dialog, a sheet, a toast.
  final List<BoxShadow> overlay;

  static List<BoxShadow> _card(double alpha) => [
    BoxShadow(
      color: AppPalette.shadow.withValues(alpha: alpha),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> _raised(double alpha) => [
    BoxShadow(
      color: AppPalette.shadow.withValues(alpha: alpha),
      blurRadius: 6,
      spreadRadius: -1,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppPalette.shadow.withValues(alpha: alpha),
      blurRadius: 4,
      spreadRadius: -2,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> _overlay(double alpha) => [
    BoxShadow(
      color: AppPalette.shadow.withValues(alpha: alpha),
      blurRadius: 15,
      spreadRadius: -3,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: AppPalette.shadow.withValues(alpha: alpha),
      blurRadius: 6,
      spreadRadius: -4,
      offset: const Offset(0, 4),
    ),
  ];

  @override
  AppShadows copyWith({
    List<BoxShadow>? card,
    List<BoxShadow>? raised,
    List<BoxShadow>? overlay,
  }) {
    return AppShadows(
      card: card ?? this.card,
      raised: raised ?? this.raised,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  AppShadows lerp(AppShadows? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      card: BoxShadow.lerpList(card, other.card, t)!,
      raised: BoxShadow.lerpList(raised, other.raised, t)!,
      overlay: BoxShadow.lerpList(overlay, other.overlay, t)!,
    );
  }
}
