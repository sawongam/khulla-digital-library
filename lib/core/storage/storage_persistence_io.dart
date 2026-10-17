// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Always null: a native catalogue is a file on disk, not browser storage.
Future<bool?> isStoragePersistent() async => null;

/// Always null: there is nothing to ask for on a native build.
Future<bool?> requestPersistentStorage() async => null;
