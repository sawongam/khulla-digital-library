// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';
import 'package:khulla_ui/src/theme/app_palette.dart';

/// Semantic colors Material's [ColorScheme] has no role for.
///
/// Three groups live here. The **ink ramp** (`ink100`…`ink600`) is the text
/// scale, and it inverts with the theme - `ink100` is the darkest ink in
/// light mode and the lightest in dark. The **status** colors carry meaning
/// (`success`, `warning`, `info`, `danger`), each with the ink, the ink's
/// contrast for a solid fill, and the wash a badge sits on. The **surface**
/// colors ([hairline], [secondary], [muted]) are the structure: this design
/// builds depth out of 1px rules and low-alpha tints, not out of elevation.
///
/// Every hover, active, selected and zebra surface in the product is an alpha
/// tint of one of these - read them from [tints] rather than inventing an
/// alpha at a call site, or the table stops matching the navigation rail.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.accent,
    required this.ink100,
    required this.ink200,
    required this.ink300,
    required this.ink400,
    required this.ink500,
    required this.ink600,
    required this.secondary,
    required this.muted,
    required this.mutedForeground,
    required this.premium,
    required this.success,
    required this.onSuccess,
    required this.successSoft,
    required this.warning,
    required this.onWarning,
    required this.warningSoft,
    required this.info,
    required this.onInfo,
    required this.infoSoft,
    required this.danger,
    required this.onDanger,
    required this.dangerSoft,
    required this.neutralSoft,
    required this.brandSoft,
    required this.brandStrong,
    required this.brandDeep,
    required this.textHigh,
    required this.textMuted,
    required this.hairline,
    required this.hairlineStrong,
    required this.paper,
    required this.paperElevated,
    required this.onPaper,
  });

  /// The light palette - the shipped theme.
  ///
  /// [brand] is the only variable: everything else is fixed, so an operator
  /// picking a different brand moves the five brand roles and nothing else.
  factory AppColors.light([AppBrand brand = AppBrand.teal]) => AppColors(
    brand: brand.seed,
    accent: brand.accent,
    ink100: AppPalette.ink100Light,
    ink200: AppPalette.ink200Light,
    ink300: AppPalette.ink300Light,
    ink400: AppPalette.ink400Light,
    ink500: AppPalette.ink500Light,
    ink600: AppPalette.ink600Light,
    secondary: AppPalette.secondaryLight,
    muted: AppPalette.white300,
    mutedForeground: AppPalette.mutedForegroundLight,
    premium: AppPalette.premium,
    success: AppPalette.success,
    onSuccess: AppPalette.white100,
    successSoft: _wash(AppPalette.success),
    warning: AppPalette.warning,
    onWarning: AppPalette.white100,
    warningSoft: _wash(AppPalette.warning),
    info: AppPalette.info,
    onInfo: AppPalette.white100,
    infoSoft: _wash(AppPalette.info),
    danger: AppPalette.danger,
    onDanger: AppPalette.white100,
    dangerSoft: _wash(AppPalette.danger),
    neutralSoft: AppPalette.secondaryLight,
    brandSoft: _tint(brand.accent, 0.2),
    brandStrong: brand.strong,
    brandDeep: brand.deep,
    textHigh: AppPalette.ink100Light,
    textMuted: AppPalette.ink500Light,
    hairline: AppPalette.borderLight,
    hairlineStrong: AppPalette.ink700,
    paper: AppPalette.paper,
    paperElevated: AppPalette.paperElevated,
    onPaper: AppPalette.onPaper,
  );

  /// The dark palette. Complete, so enabling dark is a data change rather
  /// than a rewrite.
  factory AppColors.dark([AppBrand brand = AppBrand.teal]) => AppColors(
    brand: brand.seed,
    accent: AppPalette.white400,
    ink100: AppPalette.ink100Dark,
    ink200: AppPalette.ink200Dark,
    ink300: AppPalette.ink300Dark,
    ink400: AppPalette.ink400Dark,
    ink500: AppPalette.ink500Dark,
    ink600: AppPalette.ink600Dark,
    secondary: AppPalette.surfaceDark,
    muted: AppPalette.mutedDark,
    mutedForeground: AppPalette.white300,
    premium: AppPalette.premium,
    success: AppPalette.success,
    onSuccess: AppPalette.white100,
    successSoft: _wash(AppPalette.success, 0.14, AppPalette.surfaceDark),
    warning: AppPalette.warning,
    onWarning: AppPalette.white100,
    warningSoft: _wash(AppPalette.warning, 0.14, AppPalette.surfaceDark),
    info: AppPalette.info,
    onInfo: AppPalette.white100,
    infoSoft: _wash(AppPalette.info, 0.14, AppPalette.surfaceDark),
    danger: AppPalette.danger,
    onDanger: AppPalette.white100,
    dangerSoft: _wash(AppPalette.danger, 0.18, AppPalette.surfaceDark),
    neutralSoft: AppPalette.surfaceDark,
    brandSoft: _tint(brand.accent, 0.16),
    brandStrong: brand.strong,
    brandDeep: brand.deep,
    textHigh: AppPalette.ink100Dark,
    textMuted: AppPalette.ink500Dark,
    hairline: AppPalette.borderDark,
    hairlineStrong: AppPalette.mutedDark,
    paper: AppPalette.paper,
    paperElevated: AppPalette.paperElevated,
    onPaper: AppPalette.onPaper,
  );

  /// The one saturated hue in the chrome: primary action, active navigation, focus ring, required marker.
  final Color brand;

  /// The tint source. Never painted at full strength - every hover, active and selected surface is this color at 3–30% alpha.
  final Color accent;

  /// Primary text. Sits above `onSurface` for a page title or a figure.
  final Color ink100;

  /// Form labels and dialog titles.
  final Color ink200;

  /// Sub-navigation text.
  final Color ink300;

  /// Navigation links at rest, filter labels.
  final Color ink400;

  /// Secondary and meta text, outline-button ink.
  final Color ink500;

  /// Tertiary text.
  final Color ink600;

  /// The secondary surface: secondary button, ghost hover, tab track.
  final Color secondary;

  /// Separators and muted fills.
  final Color muted;

  /// Placeholders, captions, table-head ink, selection counts.
  final Color mutedForeground;

  /// Highlight accent for a premium or featured marker.
  final Color premium;

  /// Returned on time, available, active member.
  final Color success;

  /// Content on a solid [success] fill.
  final Color onSuccess;

  /// The wash a success badge or icon chip sits on.
  final Color successSoft;

  /// Due soon, last copy out, membership expiring.
  final Color warning;

  /// Content on a solid [warning] fill.
  final Color onWarning;

  /// The wash a warning badge sits on.
  final Color warningSoft;

  /// Reserved, on hold, imported.
  final Color info;

  /// Content on a solid [info] fill.
  final Color onInfo;

  /// The wash an info badge sits on.
  final Color infoSoft;

  /// Overdue, lost, destructive. The one alarm color, distinct from [brand].
  final Color danger;

  /// Content on a solid [danger] fill.
  final Color onDanger;

  /// The wash a danger badge sits on.
  final Color dangerSoft;

  /// The wash an inert badge or a muted icon chip sits on.
  final Color neutralSoft;

  /// The wash behind an active navigation row or a brand icon chip - [accent] at 20%.
  final Color brandSoft;

  /// Hovered / pressed brand.
  final Color brandStrong;

  /// Deeper brand for emphasis text and gradient ends.
  final Color brandDeep;

  /// High-emphasis text. Alias of [ink100]; kept because it names the role rather than the rung.
  final Color textHigh;

  /// Secondary and supporting text. Alias of [ink500].
  final Color textMuted;

  /// The single hairline every card, row and section is separated by.
  final Color hairline;

  /// The line color one step stronger: checkbox borders, connectors, a divider that must survive next to a filled surface. Does not invert.
  final Color hairlineStrong;

  /// Long-form reading surface. Theme-invariant on purpose.
  final Color paper;

  /// The raised end of a [paper] surface.
  final Color paperElevated;

  /// Content on [paper]. Never pair `onSurface` with [paper].
  final Color onPaper;

  /// The alpha composites every interactive surface is painted with.
  AppTints get tints => AppTints(this);

  /// Skeleton fill. Flat and un-animated in color; the pulse is opacity.
  Color get skeleton =>
      hairline == AppPalette.borderLight ? AppPalette.skeleton : muted;

  /// The wash initials sit on when an avatar has no image.
  Color get avatarFallback => AppPalette.avatarFallback;

  /// Link ink. A real blue, and the only one in the system.
  Color get link => AppPalette.link;

  /// The grey a ripple spawns in on a light-surfaced control.
  Color get rippleNeutral => AppPalette.rippleNeutral;

  @override
  AppColors copyWith({
    Color? brand,
    Color? accent,
    Color? ink100,
    Color? ink200,
    Color? ink300,
    Color? ink400,
    Color? ink500,
    Color? ink600,
    Color? secondary,
    Color? muted,
    Color? mutedForeground,
    Color? premium,
    Color? success,
    Color? onSuccess,
    Color? successSoft,
    Color? warning,
    Color? onWarning,
    Color? warningSoft,
    Color? info,
    Color? onInfo,
    Color? infoSoft,
    Color? danger,
    Color? onDanger,
    Color? dangerSoft,
    Color? neutralSoft,
    Color? brandSoft,
    Color? brandStrong,
    Color? brandDeep,
    Color? textHigh,
    Color? textMuted,
    Color? hairline,
    Color? hairlineStrong,
    Color? paper,
    Color? paperElevated,
    Color? onPaper,
  }) {
    return AppColors(
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      ink100: ink100 ?? this.ink100,
      ink200: ink200 ?? this.ink200,
      ink300: ink300 ?? this.ink300,
      ink400: ink400 ?? this.ink400,
      ink500: ink500 ?? this.ink500,
      ink600: ink600 ?? this.ink600,
      secondary: secondary ?? this.secondary,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      premium: premium ?? this.premium,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningSoft: warningSoft ?? this.warningSoft,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoSoft: infoSoft ?? this.infoSoft,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      neutralSoft: neutralSoft ?? this.neutralSoft,
      brandSoft: brandSoft ?? this.brandSoft,
      brandStrong: brandStrong ?? this.brandStrong,
      brandDeep: brandDeep ?? this.brandDeep,
      textHigh: textHigh ?? this.textHigh,
      textMuted: textMuted ?? this.textMuted,
      hairline: hairline ?? this.hairline,
      hairlineStrong: hairlineStrong ?? this.hairlineStrong,
      paper: paper ?? this.paper,
      paperElevated: paperElevated ?? this.paperElevated,
      onPaper: onPaper ?? this.onPaper,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brand: Color.lerp(brand, other.brand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      ink100: Color.lerp(ink100, other.ink100, t)!,
      ink200: Color.lerp(ink200, other.ink200, t)!,
      ink300: Color.lerp(ink300, other.ink300, t)!,
      ink400: Color.lerp(ink400, other.ink400, t)!,
      ink500: Color.lerp(ink500, other.ink500, t)!,
      ink600: Color.lerp(ink600, other.ink600, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      neutralSoft: Color.lerp(neutralSoft, other.neutralSoft, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandStrong: Color.lerp(brandStrong, other.brandStrong, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      textHigh: Color.lerp(textHigh, other.textHigh, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineStrong: Color.lerp(hairlineStrong, other.hairlineStrong, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paperElevated: Color.lerp(paperElevated, other.paperElevated, t)!,
      onPaper: Color.lerp(onPaper, other.onPaper, t)!,
    );
  }
}

/// The tint table.
///
/// Reproduced as alpha over whatever surface is underneath, never as a
/// pre-mixed opaque color: pre-mixing against white drifts the moment the
/// surface below changes - inside a dialog, on a zebra row, in dark mode.
extension type AppTints(AppColors _c) {
  /// Navigation row, hovered *and* active. One tint carries both states.
  Color get navRow => _c.accent.withValues(alpha: 0.2);

  /// A selected table row.
  Color get rowSelected => _c.accent.withValues(alpha: 0.1);

  /// The zebra stripe on even rows.
  Color get rowZebra => _c.hairlineStrong.withValues(alpha: 0.1);

  /// A hovered table row.
  Color get rowHover => _c.muted.withValues(alpha: 0.5);

  /// A row the app is pointing the operator at - a just-created record.
  Color get rowHighlight => _c.brand.withValues(alpha: 0.1);

  /// The table header fill.
  Color get tableHeader => _c.ink500.withValues(alpha: 0.05);

  /// The table footer fill, one step stronger than the header.
  Color get tableFooter => _c.ink500.withValues(alpha: 0.1);

  /// The track a segmented control sits on.
  Color get tabTrack => _c.hairlineStrong.withValues(alpha: 0.1);

  /// A focused or hovered menu item.
  Color get menuItemFocus => _c.secondary.withValues(alpha: 0.5);

  /// A filter chip that has a value set.
  Color get filterActive => _c.brand.withValues(alpha: 0.05);

  /// The hover fill under a destructive action.
  Color get destructiveHover => _c.danger.withValues(alpha: 0.1);

  /// The hover fill under a positive outlined action.
  Color get successHover => _c.success.withValues(alpha: 0.1);

  /// The switch track when on.
  Color get switchTrackOn => _c.accent.withValues(alpha: 0.3);

  /// The scrim behind a dialog or a side sheet.
  Color get scrimDialog => AppPalette.shadow.withValues(alpha: 0.4);

  /// The scrim behind a bottom sheet, which dims much harder.
  Color get scrimSheet => AppPalette.shadow.withValues(alpha: 0.8);
}

/// A status wash: the hue at the alpha the badge pattern uses, flattened
/// against the surface it will sit on.
///
/// Flattened rather than left translucent because a badge is drawn over
/// zebra rows and tinted panels as often as over the page, and a translucent
/// wash would pick those up and read as a different status.
Color _wash(
  Color hue, [
  double alpha = 0.08,
  Color surface = AppPalette.white100,
]) => Color.alphaBlend(hue.withValues(alpha: alpha), surface);

/// A tint kept translucent, for a surface that composites over whatever is
/// beneath it rather than over the page.
Color _tint(Color hue, double alpha) => hue.withValues(alpha: alpha);
