// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Result of saving a text file, so a toast can name the path on native.
class SavedTextFile {
  const SavedTextFile({required this.filename, this.path});

  final String filename;

  /// Absolute path on native. Null on web, where the browser chose the folder.
  final String? path;
}
