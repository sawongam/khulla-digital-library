// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:khulla_ui/src/theme/app_borders.dart';
import 'package:khulla_ui/src/theme/app_breakpoints.dart';
import 'package:khulla_ui/src/theme/app_colors.dart';
import 'package:khulla_ui/src/theme/app_density.dart';
import 'package:khulla_ui/src/theme/app_metrics.dart';
import 'package:khulla_ui/src/theme/app_motion.dart';
import 'package:khulla_ui/src/theme/app_radius.dart';
import 'package:khulla_ui/src/theme/app_shadows.dart';
import 'package:khulla_ui/src/theme/app_spacing.dart';
import 'package:khulla_ui/src/theme/app_text_styles.dart';

/// Extension on [BuildContext] for design-system tokens.
extension AppThemeBuildContext on BuildContext {
  /// Ambient [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Material [TextTheme] from the ambient theme.
  TextTheme get textTheme => theme.textTheme;

  /// Material [ColorScheme] from the ambient theme.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Custom color tokens Material's [ColorScheme] does not provide.
  AppColors get appColors => theme.extension<AppColors>()!;

  /// The package's spacing scale.
  AppSpacing get appSpacing => theme.extension<AppSpacing>()!;

  /// The package's corner-radius scale.
  AppRadius get appRadius => theme.extension<AppRadius>()!;

  /// Border widths and the dashed-stroke rhythm.
  AppBorders get appBorders => theme.extension<AppBorders>()!;

  /// Control dimensions, already resolved for the ambient density.
  AppMetrics get appMetrics => theme.extension<AppMetrics>()!;

  /// Durations, curves and gesture constants.
  AppMotion get appMotion => theme.extension<AppMotion>()!;

  /// The density rung the theme was built at. Prefer reading a resolved
  /// number from [appMetrics] or [appTextStyles] over branching on this.
  AppDensity get appDensity => appMetrics.density;

  /// The elevation tokens - `card`, `raised`, `overlay`.
  AppShadows get appShadows => theme.extension<AppShadows>()!;

  /// Window size class thresholds and content caps.
  AppBreakpoints get appBreakpoints => theme.extension<AppBreakpoints>()!;

  /// Extra text styles beyond [ThemeData].
  AppTextStyles get appTextStyles => theme.extension<AppTextStyles>()!;

  /// Window size class from [MediaQuery] width.
  ///
  /// Use for page-level structure. Inside a component that must adapt to
  /// its slot, use [LayoutBuilder] instead.
  FormFactor get formFactor {
    final width = MediaQuery.sizeOf(this).width;
    return appBreakpoints.formFactorFor(width);
  }
}
