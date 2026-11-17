// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The update check's two device settings: whether it may run on its own,
/// and when it last did.
///
/// Device settings, not library ones - they live in [SharedPreferences]
/// beside the theme, never in the catalogue, so restoring a backup made on
/// another desk does not switch this one's checks on or off.
@lazySingleton
class UpdatePreferencesStorage {
  UpdatePreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _automaticKey = 'khulla.update_check_automatic';
  static const String _lastCheckedKey = 'khulla.update_last_checked';

  /// On until the operator turns it off.
  bool readAutomaticChecks() => _prefs.getBool(_automaticKey) ?? true;

  Future<void> saveAutomaticChecks({required bool enabled}) =>
      _prefs.setBool(_automaticKey, enabled);

  DateTime? readLastCheckedAt() {
    final value = _prefs.getInt(_lastCheckedKey);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<void> saveLastCheckedAt(DateTime at) =>
      _prefs.setInt(_lastCheckedKey, at.millisecondsSinceEpoch);
}
