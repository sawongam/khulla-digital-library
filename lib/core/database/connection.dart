// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/database/database_platform.dart';
import 'package:khulla/core/logging/app_logger.dart';

const String _source = 'DatabaseConnection';

/// The executor `AppDatabase` runs on, resolved for the current platform and
/// the flavor's own catalogue file.
///
/// On native this is a background isolate holding the SQLite connection, so a
/// full-catalogue query never blocks a frame. On web it is sqlite3 compiled to
/// WebAssembly running in a worker, persisted to the origin-private file
/// system where the browser allows it and IndexedDB otherwise.
///
/// The connection is lazy: nothing is opened until the first statement runs.
/// `bootstrap` forces that with `AppDatabase.warmUp` so a broken catalogue
/// fails before the first frame instead of under a librarian's first tap.
DatabaseConnection openDatabaseConnection(AppConfig config) => driftDatabase(
  name: config.databaseName,
  native: DriftNativeOptions(
    databasePath: () => resolveDatabasePath(config.databaseName),
    setup: configureNativeConnection,
  ),
  web: DriftWebOptions(
    // Relative to the deployed web root; `make db-web` puts both there.
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
    onResult: _reportWebStorage,
  ),
);

/// Records which storage tier the browser actually granted.
///
/// This is not diagnostics for their own sake. When a browser offers nothing
/// persistent, drift falls back to `inMemory` and succeeds — a librarian would
/// enter a day of circulation and lose it on refresh, with no error anywhere.
/// Logging it is the floor; a web build that becomes a system of record needs
/// to say so on screen.
void _reportWebStorage(WasmDatabaseResult result) {
  if (result.missingFeatures.isEmpty) {
    AppLogger.info(
      'Web storage: ${result.chosenImplementation}',
      source: _source,
    );
    return;
  }

  AppLogger.warn(
    'Web storage fell back to ${result.chosenImplementation} because this '
    'browser is missing ${result.missingFeatures}.',
    source: _source,
  );
}
