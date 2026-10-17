// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Whether the browser has promised to keep the catalogue.
///
/// On the web the catalogue lives in the origin's OPFS/IndexedDB storage,
/// which browsers treat as *best-effort* by default: under storage pressure,
/// or (in Safari) after a stretch without a visit, they may clear it without
/// asking. Asking for *persistent* storage
/// (`navigator.storage.persist()`) changes that - the data then goes only
/// when the person clearing their browser chooses it. For an app holding a
/// library's only copy of its records that promise is worth asking for.
///
/// Both functions answer null where the question does not apply: a native
/// build keeps the catalogue in a file the operating system never evicts.
/// Neither throws - a browser that cannot answer is reported as null too.
library;

export 'storage_persistence_web.dart'
    if (dart.library.io) 'storage_persistence_io.dart';
