// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:khulla/core/files/saved_text_file.dart';
import 'package:khulla/core/files/share_mobile_file.dart';

/// Writes rows as CSV to a location the operator picked.
///
/// On Android/iOS there is no save dialog (`getSaveLocation` is not
/// implemented there), so the rows go to a temp file opened in the system
/// share sheet instead.
///
/// A field containing a comma, a quote or a newline is wrapped in quotes with
/// its own quotes doubled - the one escaping rule CSV has. Returns null when
/// the operator cancels the save dialog (or dismisses the sheet), the same
/// as `saveTextFile`.
Future<SavedTextFile?> saveCsvFile({
  required String filename,
  required List<String> header,
  required List<List<String>> rows,
}) async {
  final buffer = StringBuffer()..writeln(_csvRow(header));
  for (final row in rows) {
    buffer.writeln(_csvRow(row));
  }

  final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
  final file = XFile.fromData(bytes, mimeType: 'text/csv', name: filename);
  if (kIsWeb) {
    await file.saveTo(filename);
    return SavedTextFile(filename: filename);
  }

  if (isMobileShareTarget) {
    final path = await shareMobileFile(
      filename: filename,
      bytes: bytes,
      mimeType: 'text/csv',
    );
    if (path == null) return null;
    return SavedTextFile(filename: filename, path: path);
  }

  final location = await getSaveLocation(suggestedName: filename);
  if (location == null) return null;

  await file.saveTo(location.path);
  return SavedTextFile(filename: filename, path: location.path);
}

String _csvRow(List<String> fields) => fields.map(_csvField).join(',');

String _csvField(String value) {
  var field = value;
  // Neutralize formula injection: a cell starting with = + - @ (or a tab/CR
  // that trims to one) executes as a formula when the CSV is opened in a
  // spreadsheet. Prefixing with a single quote keeps the text visible while
  // stopping evaluation.
  if (field.isNotEmpty &&
      const ['=', '+', '-', '@', '\t', '\r'].contains(field[0])) {
    field = "'$field";
  }
  final needsQuoting =
      field.contains(',') ||
      field.contains('"') ||
      field.contains('\n') ||
      field.contains('\r');
  if (!needsQuoting) return field;
  return '"${field.replaceAll('"', '""')}"';
}
