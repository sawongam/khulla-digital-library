// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/theme/app_language.dart';
import 'package:khulla_ui/khulla_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper around [SharedPreferences] for the user's appearance
/// choices.
///
/// Both are stored by enum name rather than by index, so reordering
/// [AppBrandTheme] cannot silently repaint every install, and a name that no
/// longer exists falls back to the default instead of throwing.
@lazySingleton
class ThemeStorage {
  ThemeStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _themeModeKey = 'khulla.theme_mode';
  static const String _brandThemeKey = 'khulla.brand_theme';
  static const String _customBrandKey = 'khulla.brand_custom';
  static const String _languageKey = 'khulla.app_language';

  /// The persisted choice, or [ThemeMode.light] when none was saved yet.
  ThemeMode readThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeModeKey, mode.name);

  /// The persisted brand, or [AppBrandTheme.teal] when none was saved yet.
  AppBrandTheme readBrandTheme() {
    final value = _prefs.getString(_brandThemeKey);
    return AppBrandTheme.values.firstWhere(
      (brand) => brand.name == value,
      orElse: () => AppBrandTheme.teal,
    );
  }

  /// The mixed color in use, or null when the brand is one of the presets.
  ///
  /// Stored as a packed ARGB int — a color has no name to key it by, and a
  /// hex string would need parsing and a rule for what a corrupt one means.
  Color? readCustomBrand() {
    final value = _prefs.getInt(_customBrandKey);
    return value == null ? null : Color(value);
  }

  /// Writes both halves of the brand choice together, so a preset can never
  /// be left with a stale custom color sitting on top of it.
  Future<void> saveBrand(AppBrandTheme brand, Color? customSeed) async {
    await _prefs.setString(_brandThemeKey, brand.name);
    if (customSeed == null) {
      await _prefs.remove(_customBrandKey);
    } else {
      await _prefs.setInt(_customBrandKey, customSeed.toARGB32());
    }
  }

  /// The persisted interface language, or [AppLanguage.english] when none
  /// was saved yet.
  AppLanguage readAppLanguage() {
    final value = _prefs.getString(_languageKey);
    return AppLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> saveAppLanguage(AppLanguage language) =>
      _prefs.setString(_languageKey, language.name);
}
