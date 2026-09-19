// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

const String _source = 'DatabasePlatform';

/// Absolute path of the catalogue file for a database named [name].
///
/// Application support, not documents: the catalogue is app-managed state, so
/// it should not sit in a folder the user is invited to reorganise or sync.
/// `drift_flutter` defaults to the documents directory, which is why this
/// override is load-bearing rather than decorative.
Future<String> resolveDatabasePath(String name) async {
  final directory = await getApplicationSupportDirectory();
  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }
  return p.join(directory.path, '$name.sqlite');
}

/// Runs on every raw connection, inside the background isolate drift opens it
/// on. Must stay a top-level function: it is sent across an isolate boundary,
/// so it may not capture anything.
void configureNativeConnection(CommonDatabase database) {
  // `journal_mode` reports the mode it ended up in rather than failing, so a
  // file system that refuses WAL - a network share, some sandboxes - quietly
  // stays on the rollback journal. That is correct, just slower, and must
  // never stop the catalogue from opening.
  try {
    database.execute('PRAGMA journal_mode = WAL');
  } on SqliteException catch (error) {
    AppLogger.warn(
      'Could not enable write-ahead logging; continuing on the default '
      'journal mode.',
      source: _source,
      error: error,
    );
  }
}
