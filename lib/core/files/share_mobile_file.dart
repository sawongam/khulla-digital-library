// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// True on Android/iOS, where `file_selector`'s `getSaveLocation` is not
/// implemented and throws `UnimplementedError`.
///
/// Mobile has no save dialog: the platform way to hand a file to the operator
/// is the system share sheet (save to Files/Drive, send it somewhere, ...).
bool get isMobileShareTarget =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Writes [bytes] to a temp file and opens the system share sheet for it.
///
/// Returns the temp path once the sheet closes, or null when the operator
/// dismisses the sheet - the same cancel contract as the `save*File`
/// helpers, so callers treat it as "no file was kept".
Future<String?> shareMobileFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final path = p.join(dir.path, filename);
  await XFile.fromData(bytes, mimeType: mimeType, name: filename).saveTo(path);

  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: mimeType, name: filename)],
      text: filename,
    ),
  );
  if (result.status == ShareResultStatus.dismissed) return null;
  return path;
}
