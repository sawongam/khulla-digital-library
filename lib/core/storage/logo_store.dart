// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Where the library's uploaded logo lives, and how to get its bytes back.
///
/// Native writes it to a file in application support and hands back its
/// path; the web build has no persistent file system to write one to, so it
/// keeps the bytes base64-encoded in the reference string itself, which is
/// then stored in `LibrarySettings.logoRef` either way. Nothing outside this
/// pair or `LibrarySettingsRepositoryImpl` should interpret a ref's contents.
library;

export 'logo_store_web.dart' if (dart.library.io) 'logo_store_io.dart';
