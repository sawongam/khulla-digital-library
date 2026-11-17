// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// The one place the app-update flow branches on platform.
///
/// Native can tell how it was installed, download an installer and start it;
/// the web build has none of that, only a page to reload. `dart.library.io`
/// selects the native implementation, the same conditional-export pattern
/// `backup_platform.dart` uses.
///
/// Both sides expose the same three functions:
/// - `detectUpdateChannel()` - how this install is updated.
/// - `downloadInstaller(client, download, onProgress:)` - fetches and checks
///   the installer, resolving to its path. Native only.
/// - `handOverToUpdate(db, config, installerPath:, runningVersion:)` - backs
///   up the catalogue and hands over to the new version. Does not return
///   when it succeeds.
library;

export 'update_platform_web.dart'
    if (dart.library.io) 'update_platform_io.dart';
