// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/theme/app_language.dart';
import 'package:khulla/core/theme/cubit/theme_cubit.dart';
import 'package:khulla/core/theme/cubit/theme_state.dart';
import 'package:khulla/features/settings/presentation/widgets/settings_brand_color_dialog.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The one settings screen that is not a placeholder.
///
/// [ThemeCubit] is an app-wide `@lazySingleton` with real storage behind it,
/// so the choice made here survives a restart. It is a device setting, not a
/// library one — nothing about it reaches the catalogue file.
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  String _label(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.system => l10n.themeModeSystem,
    ThemeMode.light => l10n.themeModeLight,
    ThemeMode.dark => l10n.themeModeDark,
  };

  AppIconSpec _icon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => AppIcons.systemMode,
    ThemeMode.light => AppIcons.lightMode,
    ThemeMode.dark => AppIcons.darkMode,
  };

  Future<void> _pickCustomBrand(
    BuildContext context,
    ThemeState appearance,
  ) async {
    final cubit = context.read<ThemeCubit>();
    final picked = await SettingsBrandColorDialog.show(
      context,
      initial: appearance.brandSeed,
    );
    if (picked == null) return;
    await cubit.setCustomBrand(picked);
  }

  String _brandLabel(AppLocalizations l10n, AppBrandTheme brand) =>
      switch (brand) {
        AppBrandTheme.teal => l10n.brandThemeTeal,
        AppBrandTheme.indigo => l10n.brandThemeIndigo,
        AppBrandTheme.blue => l10n.brandThemeBlue,
        AppBrandTheme.violet => l10n.brandThemeViolet,
        AppBrandTheme.rose => l10n.brandThemeRose,
        AppBrandTheme.amber => l10n.brandThemeAmber,
        AppBrandTheme.forest => l10n.brandThemeForest,
        AppBrandTheme.graphite => l10n.brandThemeGraphite,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return AppPageBody(
      wide: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          spacing.page,
          spacing.lg,
          spacing.page,
          spacing.xlg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, appearance) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: l10n.settingsAppearanceTheme,
                    subtitle: l10n.settingsAppearanceThemeDescription,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppSegmentedControl<ThemeMode>(
                        value: appearance.mode,
                        items: ThemeMode.values,
                        itemLabel: (value) => _label(l10n, value),
                        itemIcon: _icon,
                        onChanged: (value) =>
                            context.read<ThemeCubit>().setThemeMode(value),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  SectionCard(
                    title: l10n.settingsAppearanceBrand,
                    subtitle: l10n.settingsAppearanceBrandDescription,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppSwatchPicker<AppBrandTheme>(
                        value: appearance.customSeed == null
                            ? appearance.brandTheme
                            : null,
                        items: AppBrandTheme.values,
                        itemColor: (value) => value.seed,
                        itemLabel: (value) => _brandLabel(l10n, value),
                        onChanged: (value) =>
                            context.read<ThemeCubit>().setBrandTheme(value),
                        customColor: appearance.customSeed,
                        customLabel: l10n.settingsAppearanceBrandCustom,
                        onCustomTap: () =>
                            _pickCustomBrand(context, appearance),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  SectionCard(
                    title: l10n.settingsAppearanceLanguage,
                    subtitle: l10n.settingsAppearanceLanguageDescription,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppSegmentedControl<AppLanguage>(
                        value: appearance.language,
                        items: AppLanguage.values,
                        itemLabel: (value) => switch (value) {
                          AppLanguage.english => l10n.settingsLanguageEnglish,
                          AppLanguage.nepali => l10n.settingsLanguageNepali,
                        },
                        onChanged: (value) =>
                            context.read<ThemeCubit>().setLanguage(value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
