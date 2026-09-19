// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';
import 'dart:typed_data';

/// The web build has nowhere to persist a file, so the ref *is* the logo —
/// base64-encoded bytes, stored straight in `LibrarySettings.logoRef`.
Future<String> saveLogo(Uint8List bytes, {required String extension}) async =>
    base64Encode(bytes);

/// Decodes the base64 [ref] back into bytes.
Future<Uint8List?> loadLogo(String ref) async => base64Decode(ref);

/// No-op: there is no separate file to delete, only the DB column, which the
/// caller clears itself.
Future<void> deleteLogo(String ref) async {}
