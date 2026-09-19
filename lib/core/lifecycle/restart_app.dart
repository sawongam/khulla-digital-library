// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Ends the running app so its next launch reopens the catalogue clean.
///
/// A backup restore or an erase replaces the file or store underneath a live
/// `AppDatabase` connection — there is no supported way to swap that out from
/// under `get_it`'s cached singleton, so the app has to actually restart.
/// Native closes the process; the web build has no process to close, only a
/// page to reload. `dart.library.io` selects the native implementation, the
/// same conditional-export pattern `database_platform.dart` uses.
library;

export 'restart_app_web.dart' if (dart.library.io) 'restart_app_io.dart';
