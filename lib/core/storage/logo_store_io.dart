// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String _baseName = 'library_logo';

/// Writes [bytes] to `library_logo.<extension>` in application support,
/// clearing any previous logo file first so a re-upload with a different
/// extension does not leave the old file behind. Returns the absolute path.
Future<String> saveLogo(Uint8List bytes, {required String extension}) async {
  final directory = await getApplicationSupportDirectory();
  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }
  await _deleteExisting(directory);

  final file = File(p.join(directory.path, '$_baseName.$extension'));
  await file.writeAsBytes(bytes);
  return file.path;
}

/// Reads the logo at [ref] (a path from [saveLogo]), or null if it is gone.
Future<Uint8List?> loadLogo(String ref) async {
  final file = File(ref);
  if (!file.existsSync()) return null;
  return await file.readAsBytes();
}

/// Deletes the logo file at [ref].
Future<void> deleteLogo(String ref) async {
  final file = File(ref);
  if (file.existsSync()) await file.delete();
}

Future<void> _deleteExisting(Directory directory) async {
  await for (final entry in directory.list()) {
    if (entry is File && p.basenameWithoutExtension(entry.path) == _baseName) {
      await entry.delete();
    }
  }
}
