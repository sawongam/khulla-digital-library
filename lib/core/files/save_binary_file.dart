// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:khulla/core/files/saved_text_file.dart';
import 'package:khulla/core/files/share_mobile_file.dart';

/// Writes binary [bytes] to a location the operator picked - the same
/// `file_selector` pattern as `saveTextFile`, for content that isn't text.
///
/// On Android/iOS there is no save dialog (`getSaveLocation` is not
/// implemented there), so the bytes go to a temp file opened in the system
/// share sheet instead.
///
/// Returns null when they cancel the save dialog (or dismiss the sheet).
Future<SavedTextFile?> saveBinaryFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final file = XFile.fromData(bytes, mimeType: mimeType, name: filename);
  if (kIsWeb) {
    await file.saveTo(filename);
    return SavedTextFile(filename: filename);
  }

  if (isMobileShareTarget) {
    final path = await shareMobileFile(
      filename: filename,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (path == null) return null;
    return SavedTextFile(filename: filename, path: path);
  }

  final location = await getSaveLocation(suggestedName: filename);
  if (location == null) return null;

  await file.saveTo(location.path);
  return SavedTextFile(filename: filename, path: location.path);
}
