// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_info.freezed.dart';

/// What the backup screen's info card shows.
///
/// [lastBackupAt] and [lastRestoreAt] are this *device's* history, not the
/// catalogue's - they live in local preferences, not a table, so restoring a
/// backup made on another machine does not overwrite them with that
/// machine's history (see `BackupSessionStorage`).
@freezed
abstract class BackupInfo with _$BackupInfo {
  const factory BackupInfo({
    DateTime? lastBackupAt,
    DateTime? lastRestoreAt,

    /// Bytes on disk, native only - there is no single file to size on web.
    int? databaseSizeBytes,

    /// Where the catalogue file lives, native only.
    String? storagePath,

    /// Whether the browser has promised to keep the catalogue, web only -
    /// null on native, where the question does not arise, and when the
    /// browser cannot say. False means the catalogue is best-effort storage
    /// the browser may clear on its own.
    bool? storagePersistent,
  }) = _BackupInfo;
}
