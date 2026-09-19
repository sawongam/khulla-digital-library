// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// The one place a platform difference is allowed in the data layer.
///
/// `drift_flutter` already reconciles the three SQLite backends — a background
/// isolate over `dart:ffi` on desktop and mobile, sqlite3 compiled to
/// WebAssembly in a worker on web — so this pair only carries what drift
/// cannot decide for us:
///
/// - **where the file lives.** Native needs a path; the web build has no file
///   system, only an OPFS or IndexedDB store keyed by name.
/// - **write-ahead logging.** Native only. WAL keeps a long read (a catalogue
///   export) from blocking a concurrent write (a checkout); the WebAssembly
///   virtual file system does not support it.
///
/// The web implementation is the fallback branch so any target without
/// `dart:io` still resolves, and `dart.library.io` selects the native one.
/// Nothing else in the app may branch on the platform — no `if (kIsWeb)` in a
/// data source.
library;

export 'database_platform_web.dart'
    if (dart.library.io) 'database_platform_io.dart';
