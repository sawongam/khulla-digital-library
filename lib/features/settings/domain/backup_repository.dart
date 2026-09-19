// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/settings/domain/models/backup_info.dart';

/// Export, restore and erase for the local catalogue.
///
/// Native and web genuinely differ here — a straight file copy on native,
/// a generic table dump on web, since there is no file to copy (see
/// `backup_platform.dart`) — but both restore and erase share one property:
/// they replace what is underneath the running `AppDatabase` connection, so
/// both end by restarting the app rather than returning to a screen that
/// would otherwise read half-old, half-new state.
abstract interface class BackupRepository {
  /// The info card's figures — last backup/restore time, and, on native,
  /// the file's size and location.
  Future<BackupInfo> describeBackup();

  /// Writes a backup to a location the operator picks. Null when they
  /// cancel the save dialog.
  Future<bool> exportBackup();

  /// Lets the operator pick a backup file and restores the catalogue from
  /// it, then restarts the app. Throws `InvalidInputException` when the
  /// picked file is not a Khulla backup — nothing is overwritten first.
  /// Returns false when they cancel the picker.
  Future<bool> restoreBackup();

  /// Wipes every table, then restarts the app — it lands back on onboarding,
  /// since a catalogue with no staff account has never been set up.
  Future<void> eraseCatalogue();
}
