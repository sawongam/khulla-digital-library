// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';
import 'package:khulla_ui/src/theme/app_fonts.dart';
import 'package:khulla_ui/src/theme/app_palette.dart';

/// The app's two themes, built per density rung.
///
/// One thing changes with the window and nothing else does: **density**. Type
/// size, control height, icon size and gap step up by one notch at 1600px.
/// Colors, radii and the shape language are identical at every width - a
/// component must not change *what it is* when the window resizes, only how
/// much room it takes.
///
/// Three Material defaults are overridden globally here because they fight
/// the design language rather than merely differing from it: the ink splash
/// (replaced by the design system's own press feedback), elevation shadows
/// (replaced by [AppShadows]) and the input decorator's focus behaviour
/// (replaced by a padding nudge - see `AppTextField`).
abstract final class AppTheme {
  /// The light theme at [density], colored by [brand]. This is the shipped
  /// theme.
  static ThemeData light([
    AppDensity density = AppDensity.comfortable,
    AppBrand brand = AppBrand.teal,
  ]) => _themeFrom(Brightness.light, density, brand);

  /// The dark theme at [density], colored by [brand].
  static ThemeData dark([
    AppDensity density = AppDensity.comfortable,
    AppBrand brand = AppBrand.teal,
  ]) => _themeFrom(Brightness.dark, density, brand);

  static ThemeData _themeFrom(
    Brightness brightness,
    AppDensity density,
    AppBrand brand,
  ) {
    final isLight = brightness == Brightness.light;
    final colorScheme = _brandColorScheme(brightness, brand);
    final appColors = isLight ? AppColors.light(brand) : AppColors.dark(brand);
    final shadows = isLight ? AppShadows.light() : AppShadows.dark();
    final metrics = AppMetrics.of(density);
    final typography = AppTextStyles(density: density);
    final textTheme = typography.textTheme;
    const spacing = AppSpacing();
    const radius = AppRadius();
    const borders = AppBorders();
    const motion = AppMotion();
    const breakpoints = AppBreakpoints();

    final surface = colorScheme.surface;
    final hairline = BorderSide(color: appColors.hairline);

    final itemShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius.item),
    );
    final containerShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius.container),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius.control),
    );

    // The resting border is the same hairline on every state. Focus is not
    // signalled by recoloring it - see AppTextField.
    InputBorder fieldBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius.container),
      borderSide: BorderSide(color: color),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.poppins,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      // Material's splash is the wrong color, timing and shape for this
      // design. Press feedback is drawn by the design system's own controls.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[
        appColors,
        spacing,
        radius,
        borders,
        breakpoints,
        shadows,
        metrics,
        motion,
        typography,
      ],
      iconTheme: IconThemeData(color: appColors.ink500, size: metrics.icon),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: appColors.ink100,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: metrics.topBarHeight,
        titleTextStyle: typography.pageHeader.copyWith(color: appColors.ink100),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, metrics.buttonHeightSmall),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
          disabledForegroundColor: colorScheme.onPrimary.withValues(
            alpha: 0.5,
          ),
          padding: EdgeInsets.symmetric(horizontal: spacing.sm),
          textStyle: typography.button,
          shape: containerShape,
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, metrics.buttonHeightSmall),
          foregroundColor: appColors.ink500,
          backgroundColor: surface,
          side: hairline,
          padding: EdgeInsets.symmetric(horizontal: spacing.sm),
          textStyle: typography.button,
          shape: containerShape,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(0, metrics.buttonHeightSmall),
          foregroundColor: colorScheme.primary,
          textStyle: typography.button,
          shape: containerShape,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.pill),
        ),
        side: BorderSide.none,
        backgroundColor: appColors.secondary,
        labelStyle: typography.micro,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm - 2,
          vertical: spacing.xxs / 2,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: controlShape,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        border: fieldBorder(appColors.hairline),
        enabledBorder: fieldBorder(appColors.hairline),
        disabledBorder: fieldBorder(appColors.hairline),
        focusedBorder: fieldBorder(appColors.hairline),
        errorBorder: fieldBorder(appColors.hairline),
        focusedErrorBorder: fieldBorder(appColors.hairline),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        hintStyle: typography.body.copyWith(color: appColors.mutedForeground),
        helperStyle: typography.micro.copyWith(color: appColors.ink500),
        errorStyle: typography.micro.copyWith(color: colorScheme.error),
        prefixIconColor: AppPalette.white600,
        suffixIconColor: AppPalette.white600,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: containerShape,
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      // A menu floats, so it takes the raised depth. The elevation number
      // here only drives Material's own shadow; the geometry is chosen to
      // land on the same softness as `AppShadows.raised`.
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: AppPalette.shadow.withValues(alpha: 0.1),
        menuPadding: EdgeInsets.symmetric(vertical: spacing.xxs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.container),
          side: hairline,
        ),
        textStyle: typography.label.copyWith(color: appColors.ink200),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(EdgeInsets.all(spacing.xxs)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius.container),
              side: hairline,
            ),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: appColors.tints.scrimDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.control),
          side: hairline,
        ),
        titleTextStyle: typography.formTitle.copyWith(color: appColors.ink200),
        contentTextStyle: typography.body.copyWith(color: appColors.ink500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : appColors.ink400,
            size: metrics.iconLarge,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return typography.label.copyWith(
            color: selected ? colorScheme.primary : appColors.ink400,
          );
        }),
        elevation: 0,
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: appColors.tints.navRow,
        indicatorShape: controlShape,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: metrics.iconNav,
        ),
        unselectedIconTheme: IconThemeData(
          color: appColors.ink400,
          size: metrics.iconNav,
        ),
        selectedLabelTextStyle: typography.bodyLarge.copyWith(
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: typography.bodyLarge.copyWith(
          color: appColors.ink400,
        ),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        modalBarrierColor: appColors.tints.scrimSheet,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radius.sheet),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: appColors.hairline,
        thickness: borders.hairline,
        space: borders.hairline,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: itemShape,
        side: BorderSide(
          color: appColors.hairlineStrong,
          width: borders.checkbox,
        ),
        fillColor: const WidgetStatePropertyAll(Colors.transparent),
        checkColor: WidgetStatePropertyAll(colorScheme.primary),
        visualDensity: VisualDensity.compact,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : appColors.hairlineStrong,
        ),
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? appColors.tints.switchTrackOn
              : AppPalette.white600.withValues(alpha: 0.5),
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : surface,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.2),
        circularTrackColor: Colors.transparent,
        linearMinHeight: spacing.xs,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: appColors.ink400,
        indicatorColor: colorScheme.primary,
        dividerColor: appColors.hairline,
        labelStyle: typography.label,
        unselectedLabelStyle: typography.label,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      // The thumb is a hint, not furniture: it fades in while the view is
      // moving or the pointer is over it, and is gone otherwise. A permanent
      // 8px slab down the middle of a constrained page reads as a seam
      // between two panes rather than as a scrollbar.
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thickness: const WidgetStatePropertyAll(6),
        radius: Radius.circular(radius.pill),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final base = appColors.ink100;
          if (states.contains(WidgetState.dragged)) {
            return base.withValues(alpha: 0.36);
          }
          if (states.contains(WidgetState.hovered)) {
            return base.withValues(alpha: 0.24);
          }
          return base.withValues(alpha: 0.12);
        }),
      ),
      // A light tooltip with a hairline, not Material's dark slab.
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(radius.container),
          border: Border.fromBorderSide(hairline),
          boxShadow: shadows.raised,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xxs + 2,
        ),
        textStyle: typography.bodyLarge.copyWith(color: appColors.ink100),
      ),
    );
  }

  static ColorScheme _brandColorScheme(Brightness brightness, AppBrand brand) {
    final seeded = ColorScheme.fromSeed(
      seedColor: brand.seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    );

    if (brightness == Brightness.light) {
      return seeded.copyWith(
        primary: brand.seed,
        onPrimary: brand.onBrand,
        primaryContainer: brand.tint,
        onPrimaryContainer: brand.seed,
        secondary: AppPalette.secondaryLight,
        onSecondary: AppPalette.ink100Light,
        secondaryContainer: AppPalette.secondaryLight,
        onSecondaryContainer: AppPalette.ink100Light,
        tertiary: brand.deep,
        onTertiary: AppPalette.white100,
        tertiaryContainer: brand.tintFaint,
        onTertiaryContainer: brand.deep,
        error: AppPalette.danger,
        onError: AppPalette.white100,
        errorContainer: AppPalette.dangerTint,
        onErrorContainer: AppPalette.dangerStrong,
        surface: AppPalette.white100,
        onSurface: AppPalette.ink100Light,
        onSurfaceVariant: AppPalette.ink500Light,
        surfaceContainerLowest: AppPalette.white100,
        surfaceContainerLow: AppPalette.white100,
        surfaceContainer: AppPalette.secondaryLight,
        surfaceContainerHigh: AppPalette.white200,
        surfaceContainerHighest: AppPalette.white200,
        surfaceTint: Colors.transparent,
        outline: AppPalette.ink700,
        outlineVariant: AppPalette.borderLight,
        shadow: AppPalette.shadow,
        inverseSurface: AppPalette.ink100Light,
        onInverseSurface: AppPalette.white100,
      );
    }

    return seeded.copyWith(
      primary: brand.seed,
      onPrimary: brand.onBrand,
      primaryContainer: AppPalette.surfaceDark,
      onPrimaryContainer: AppPalette.ink100Dark,
      secondary: AppPalette.surfaceDark,
      onSecondary: AppPalette.ink100Dark,
      secondaryContainer: AppPalette.surfaceDark,
      onSecondaryContainer: AppPalette.ink100Dark,
      tertiary: brand.accent,
      onTertiary: AppPalette.ink100Light,
      tertiaryContainer: AppPalette.surfaceDark,
      onTertiaryContainer: brand.accent,
      error: AppPalette.danger,
      onError: AppPalette.white100,
      errorContainer: AppPalette.surfaceDark,
      onErrorContainer: AppPalette.danger,
      surface: AppPalette.backgroundDark,
      onSurface: AppPalette.ink100Dark,
      onSurfaceVariant: AppPalette.ink500Dark,
      surfaceContainerLowest: AppPalette.backgroundDark,
      surfaceContainerLow: AppPalette.backgroundDark,
      surfaceContainer: AppPalette.surfaceDark,
      surfaceContainerHigh: AppPalette.surfaceDark,
      surfaceContainerHighest: AppPalette.mutedDark,
      surfaceTint: Colors.transparent,
      outline: AppPalette.mutedDark,
      outlineVariant: AppPalette.borderDark,
      shadow: AppPalette.shadow,
      inverseSurface: AppPalette.white100,
      onInverseSurface: AppPalette.ink100Light,
    );
  }
}
