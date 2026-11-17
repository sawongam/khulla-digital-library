// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// One file of a release, as the release manifest describes it.
///
/// [sha256] and [sizeBytes] are what a finished download is checked against
/// before anything runs it: a download cut short, or mangled by a proxy,
/// never reaches the installer.
final class UpdateDownload {
  const UpdateDownload({
    required this.url,
    required this.sha256,
    required this.sizeBytes,
  });

  /// Where the file is served from. Always `https`.
  final Uri url;

  /// The file's SHA-256, lowercase hex.
  final String sha256;

  /// The file's exact length.
  final int sizeBytes;

  /// The file's own name, the last segment of [url].
  String get fileName => url.pathSegments.last;
}
