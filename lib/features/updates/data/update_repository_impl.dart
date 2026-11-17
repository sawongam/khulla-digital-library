// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/config/app_version.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/updates/data/installed_update_channel.dart';
import 'package:khulla/features/updates/data/update_manifest_remote_data_source.dart';
import 'package:khulla/features/updates/data/update_platform.dart';
import 'package:khulla/features/updates/data/update_preferences_storage.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/domain/models/update_release.dart';
import 'package:khulla/features/updates/domain/update_repository.dart';
import 'package:khulla/features/updates/domain/update_rules.dart';

@LazySingleton(as: UpdateRepository)
class UpdateRepositoryImpl implements UpdateRepository {
  UpdateRepositoryImpl(
    this._manifest,
    this._preferences,
    this._client,
    this._db,
    this._config,
    InstalledUpdateChannel installed,
  ) : channel = installed.channel,
      // Read now, while the page is the one that was loaded. On the web the
      // platform answers from the server's `version.json`, so a first read
      // after a deploy would report the *new* version as the running one
      // and the check would never see the difference.
      _running = (AppVersion.version(), AppVersion.buildNumber());

  final UpdateManifestRemoteDataSource _manifest;
  final UpdatePreferencesStorage _preferences;
  final http.Client _client;
  final AppDatabase _db;
  final AppConfig _config;
  final (Future<String>, Future<int?>) _running;

  @override
  final UpdateChannel channel;

  @override
  Future<String> runningVersion() => _running.$1;

  @override
  Future<UpdateRelease?> findNewerRelease() async {
    if (!channel.checksForUpdates) return null;
    final release = await _manifest.fetchLatestRelease(channel);
    await _preferences.saveLastCheckedAt(DateTime.now());
    final newer = isNewerRelease(
      runningVersion: await _running.$1,
      runningBuild: await _running.$2,
      releaseVersion: release.version,
      releaseBuild: release.build,
    );
    return newer ? release : null;
  }

  @override
  bool get automaticChecksEnabled => _preferences.readAutomaticChecks();

  @override
  Future<void> saveAutomaticChecksEnabled({required bool enabled}) =>
      _preferences.saveAutomaticChecks(enabled: enabled);

  /// Never in the dev flavor: a developer's machine asking GitHub on every
  /// launch is noise, and the manual check still works there.
  @override
  bool get isAutomaticCheckDue =>
      _config.isProduction &&
      channel.checksForUpdates &&
      automaticChecksEnabled &&
      isUpdateCheckDue(
        lastCheckedAt: _preferences.readLastCheckedAt(),
        now: DateTime.now(),
      );

  @override
  Future<String> downloadUpdate(
    UpdateRelease release, {
    required void Function(double progress) onProgress,
  }) {
    final download = release.download;
    if (!channel.downloadsInstaller || download == null) {
      throw const StorageException.because(
        AppErrorReason.updateDownloadFailed,
      );
    }
    return downloadInstaller(_client, download, onProgress: onProgress);
  }

  @override
  Future<void> applyUpdate({String? installerPath}) async {
    if (!channel.installsInApp) {
      throw const StorageException.because(AppErrorReason.updateInstallFailed);
    }
    await handOverToUpdate(
      _db,
      _config,
      installerPath: installerPath,
      runningVersion: await _running.$1,
    );
  }
}
