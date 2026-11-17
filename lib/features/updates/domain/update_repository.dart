// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/domain/models/update_release.dart';

/// Finding, fetching and applying a newer version of the app.
///
/// Every failure is an `AppException` with a reason the dialog can read out:
/// a check that could not reach the server, a download that broke off or
/// arrived damaged, an installer that would not start.
abstract interface class UpdateRepository {
  /// How this install is updated. Fixed for the life of the process.
  UpdateChannel get channel;

  /// The running version, `1.2.3`.
  Future<String> runningVersion();

  /// The latest release when it is newer than the running app, otherwise
  /// null. Records the time of the check, so the automatic one waits a day.
  Future<UpdateRelease?> findNewerRelease();

  /// Whether the app may check on its own. On unless the operator turned it
  /// off.
  bool get automaticChecksEnabled;

  Future<void> saveAutomaticChecksEnabled({required bool enabled});

  /// Whether an automatic check should run now: allowed, on a channel that
  /// checks, in the release build, and a day since the last one.
  bool get isAutomaticCheckDue;

  /// Downloads [release]'s installer and checks it against the manifest.
  /// Resolves to where it was saved. [onProgress] runs with 0.0-1.0 as bytes
  /// arrive.
  Future<String> downloadUpdate(
    UpdateRelease release, {
    required void Function(double progress) onProgress,
  });

  /// Backs up the catalogue and hands over to the new version: on Windows,
  /// starts the installer at [installerPath] and ends this process; on the
  /// web, reloads the page. Does not return when it succeeds.
  Future<void> applyUpdate({String? installerPath});
}
