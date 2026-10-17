// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:js_interop';

import 'package:khulla/core/logging/app_logger.dart';
import 'package:web/web.dart' as web;

const String _source = 'StoragePersistence';

/// Whether this origin's storage is already persistent; null when the
/// browser cannot say.
Future<bool?> isStoragePersistent() async {
  try {
    return (await web.window.navigator.storage.persisted().toDart).toDart;
  } on Object catch (error) {
    AppLogger.warn(
      'Could not read the storage persistence state.',
      source: _source,
      error: error,
    );
    return null;
  }
}

/// Asks the browser to keep this origin's storage, and answers whether it
/// now does; null when the browser cannot say.
///
/// Already persistent is answered at once with no prompt. Otherwise Chrome
/// and Safari decide from how the site is used (installed, bookmarked,
/// visited often) without asking, and Firefox asks the person once.
Future<bool?> requestPersistentStorage() async {
  try {
    final storage = web.window.navigator.storage;
    if ((await storage.persisted().toDart).toDart) return true;
    final granted = (await storage.persist().toDart).toDart;
    if (!granted) {
      AppLogger.warn(
        'The browser declined persistent storage; the catalogue stays '
        'best-effort and could be cleared under storage pressure.',
        source: _source,
      );
    }
    return granted;
  } on Object catch (error) {
    AppLogger.warn(
      'Could not request persistent storage.',
      source: _source,
      error: error,
    );
    return null;
  }
}
