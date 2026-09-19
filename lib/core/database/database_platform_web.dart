// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:sqlite3/common.dart';

/// Unreachable on web: the browser build has no file system to resolve a path
/// against. `drift_flutter` keys its OPFS or IndexedDB store on the database
/// name alone and never calls this.
Future<String> resolveDatabasePath(String name) {
  throw UnsupportedError(
    'The web build stores the catalogue in the browser, not at a path.',
  );
}

/// No-op on web. The WebAssembly virtual file system does not implement
/// write-ahead logging, and drift never invokes this hook there.
void configureNativeConnection(CommonDatabase database) {}
