// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/theme/app_language.dart';
import 'package:khulla/core/theme/cubit/theme_state.dart';
import 'package:khulla/core/theme/theme_storage.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// App-wide appearance and language: [ThemeMode], the brand the product is
/// painted in, and the [AppLanguage] the interface is drawn in.
///
/// All are read from [ThemeStorage] on startup and persisted on every change,
/// so the choice survives a restart. They are device settings, not library
/// ones — nothing here reaches the catalogue file.
@lazySingleton
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._storage)
    : super(
        ThemeState(
          mode: _storage.readThemeMode(),
          brandTheme: _storage.readBrandTheme(),
          customSeed: _storage.readCustomBrand(),
          language: _storage.readAppLanguage(),
        ),
      );

  final ThemeStorage _storage;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.mode == mode) return;
    emit(state.copyWith(mode: mode));
    await _storage.saveThemeMode(mode);
  }

  /// Cycles system → light → dark → system, for a single toolbar control.
  Future<void> cycleThemeMode() => setThemeMode(switch (state.mode) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });

  Future<void> setBrandTheme(AppBrandTheme brand) async {
    if (state.brandTheme == brand && state.customSeed == null) return;
    emit(state.copyWith(brandTheme: brand, customSeed: null));
    await _storage.saveBrand(brand, null);
  }

  /// Adopts a color the operator mixed rather than one of the presets.
  ///
  /// A mixed color that lands exactly on a preset is stored as that preset —
  /// otherwise the swatch row would show nothing selected while sitting next
  /// to an identical color.
  Future<void> setCustomBrand(Color seed) async {
    for (final preset in AppBrandTheme.values) {
      if (preset.seed == seed) {
        await setBrandTheme(preset);
        return;
      }
    }
    if (state.customSeed == seed) return;
    emit(state.copyWith(customSeed: seed));
    await _storage.saveBrand(state.brandTheme, seed);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state.language == language) return;
    emit(state.copyWith(language: language));
    await _storage.saveAppLanguage(language);
  }
}
