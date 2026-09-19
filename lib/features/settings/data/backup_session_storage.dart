// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers this device's own backup and restore history.
///
/// Local preferences, not a table - the same reasoning as
/// `AuthSessionStorage`. A restore replaces the catalogue's tables wholesale,
/// and a "last backup" timestamp inside them would then show whoever made
/// *that* backup's history, on a device that may never have taken one.
@lazySingleton
class BackupSessionStorage {
  BackupSessionStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _lastBackupKey = 'khulla.backup.last_backup_at';
  static const String _lastRestoreKey = 'khulla.backup.last_restore_at';

  DateTime? readLastBackupAt() => _readDateTime(_lastBackupKey);

  DateTime? readLastRestoreAt() => _readDateTime(_lastRestoreKey);

  Future<void> saveLastBackupAt(DateTime value) =>
      _prefs.setString(_lastBackupKey, value.toIso8601String());

  Future<void> saveLastRestoreAt(DateTime value) =>
      _prefs.setString(_lastRestoreKey, value.toIso8601String());

  DateTime? _readDateTime(String key) {
    final raw = _prefs.getString(key);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
