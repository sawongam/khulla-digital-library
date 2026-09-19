// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// The one place backup export/restore is allowed to branch on platform.
///
/// Native has a real `.sqlite` file on disk - export checkpoints WAL and
/// copies it, restore closes the connection and overwrites it. Web has no
/// filesystem, only OPFS or IndexedDB behind the same `AppDatabase`
/// connection - export dumps every table to JSON through that connection,
/// restore reads it back the same way. `dart.library.io` selects the native
/// implementation, the same conditional-export pattern
/// `database_platform.dart` uses.
///
/// Both sides expose the same three functions:
/// - `exportBackupBytes(db, config)` - the bytes to hand to `saveBinaryFile`
///   or `saveCsvFile`-style export.
/// - `importBackupBytes(db, config, bytes)` - restores from previously
///   exported bytes. Throws `InvalidInputException` when they are not a
///   Khulla backup, before anything is written.
/// - `inspectStorage(config)` - the info card's size/path figures, both null
///   on web.
library;

export 'backup_platform_web.dart'
    if (dart.library.io) 'backup_platform_io.dart';
