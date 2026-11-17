// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/updates/domain/models/update_download.dart';

/// A published version of Khulla, as seen from this install.
final class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.build,
    required this.notesUrl,
    this.download,
  });

  /// `1.2.3` - what a person reads.
  final String version;

  /// The `+N` of `version:` in `pubspec.yaml`. It only ever goes up, so it is
  /// what decides whether a release is newer.
  final int build;

  /// The release page: what changed, and every file it ships.
  final Uri notesUrl;

  /// The file this install would run to update itself, or null when the
  /// update is not applied in the app (see `UpdateChannel.installsInApp`).
  final UpdateDownload? download;
}
