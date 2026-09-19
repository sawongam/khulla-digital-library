// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:web/web.dart' as web;

/// Reloads the page. The web build has no process to end, only a document to
/// reopen — a reload is what makes `driftDatabase()` reconnect to whatever
/// the restore or erase just wrote to OPFS or IndexedDB.
void restartApp() => web.window.location.reload();
