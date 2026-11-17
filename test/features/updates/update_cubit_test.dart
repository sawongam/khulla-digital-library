// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/domain/models/update_download.dart';
import 'package:khulla/features/updates/domain/models/update_release.dart';
import 'package:khulla/features/updates/domain/update_repository.dart';
import 'package:khulla/features/updates/presentation/cubit/update_cubit.dart';
import 'package:khulla/features/updates/presentation/cubit/update_status.dart';

/// The update flow, step by step, against a repository that answers
/// whatever each test needs.
void main() {
  final release = UpdateRelease(
    version: '1.2.0',
    build: 7,
    notesUrl: Uri.parse('https://example.com/v1.2.0'),
    download: UpdateDownload(
      url: Uri.parse('https://example.com/setup.exe'),
      sha256: 'a' * 64,
      sizeBytes: 100,
    ),
  );

  late _FakeUpdateRepository repository;
  late UpdateCubit cubit;

  void start(UpdateChannel channel) {
    repository = _FakeUpdateRepository(channel)..latest = release;
    cubit = UpdateCubit(repository);
  }

  tearDown(() => cubit.close());

  test('a check finds the newer release and the running version', () async {
    start(UpdateChannel.windowsInstaller);

    await cubit.checkForUpdate();

    expect(cubit.state.status, UpdateStatus.available);
    expect(cubit.state.release, release);
    expect(cubit.state.runningVersion, '1.1.2');
    expect(cubit.state.hasUpdate, isTrue);
  });

  test('a check that finds nothing newer says so', () async {
    start(UpdateChannel.linux);
    repository.latest = null;

    await cubit.checkForUpdate();

    expect(cubit.state.status, UpdateStatus.upToDate);
    expect(cubit.state.hasUpdate, isFalse);
  });

  test('a failed check lands in state, and retry checks again', () async {
    start(UpdateChannel.linux);
    repository.checkError = const NetworkException.because(
      AppErrorReason.updateCheckFailed,
    );

    await cubit.checkForUpdate();
    expect(cubit.state.status, UpdateStatus.failed);
    expect(cubit.state.error?.reason, AppErrorReason.updateCheckFailed);

    repository.checkError = null;
    await cubit.retryUpdate();
    expect(cubit.state.status, UpdateStatus.available);
    expect(cubit.state.error, isNull);
  });

  test('Google Play installs never ask GitHub', () async {
    start(UpdateChannel.googlePlay);

    await cubit.checkForUpdate();
    await cubit.checkForUpdateIfDue();

    expect(repository.checks, 0);
    expect(cubit.state.status, UpdateStatus.idle);
  });

  group('the automatic check', () {
    test('runs only when due', () async {
      start(UpdateChannel.windowsInstaller);
      repository.due = false;

      await cubit.checkForUpdateIfDue();
      expect(repository.checks, 0);

      repository.due = true;
      await cubit.checkForUpdateIfDue();
      expect(repository.checks, 1);
      expect(cubit.state.hasUpdate, isTrue);
    });

    test('stays quiet when it fails', () async {
      start(UpdateChannel.windowsInstaller);
      repository
        ..due = true
        ..checkError = const NetworkException.because(
          AppErrorReason.updateCheckFailed,
        );

      await cubit.checkForUpdateIfDue();

      expect(cubit.state.status, UpdateStatus.idle);
      expect(cubit.state.error, isNull);
    });
  });

  group('on the Windows installer', () {
    setUp(() async {
      start(UpdateChannel.windowsInstaller);
      await cubit.checkForUpdate();
    });

    test('a download ends ready to install, with its path', () async {
      await cubit.downloadUpdate();

      expect(cubit.state.status, UpdateStatus.readyToInstall);
      expect(cubit.state.installerPath, '/tmp/setup.exe');
      expect(cubit.state.progress, 1);
    });

    test('reopening the dialog keeps a downloaded installer', () async {
      await cubit.downloadUpdate();
      await cubit.checkForUpdate();

      expect(cubit.state.status, UpdateStatus.readyToInstall);
      expect(repository.checks, 1);
    });

    test('a damaged download fails, and retry downloads again', () async {
      repository.downloadError = const StorageException.because(
        AppErrorReason.updateDownloadDamaged,
      );
      await cubit.downloadUpdate();
      expect(cubit.state.status, UpdateStatus.failed);
      expect(cubit.state.installerPath, isNull);

      repository.downloadError = null;
      await cubit.retryUpdate();
      expect(cubit.state.status, UpdateStatus.readyToInstall);
      expect(repository.applied, isEmpty);
    });

    test('install hands the downloaded installer over', () async {
      await cubit.downloadUpdate();
      await cubit.installUpdate();

      expect(repository.applied, ['/tmp/setup.exe']);
    });

    test('an installer that will not start fails, and retry installs '
        'again', () async {
      await cubit.downloadUpdate();
      repository.applyError = const StorageException.because(
        AppErrorReason.updateInstallFailed,
      );
      await cubit.installUpdate();
      expect(cubit.state.status, UpdateStatus.failed);

      repository.applyError = null;
      await cubit.retryUpdate();
      expect(repository.applied, ['/tmp/setup.exe', '/tmp/setup.exe']);
    });
  });

  test('a release-page APK is told about the update, never installed '
      'by the app', () async {
    start(UpdateChannel.androidApk);
    await cubit.checkForUpdate();

    expect(cubit.state.status, UpdateStatus.available);

    await cubit.installUpdate();
    await cubit.downloadUpdate();

    expect(repository.applied, isEmpty);
    expect(cubit.state.status, isNot(UpdateStatus.readyToInstall));
  });

  test('the web build installs by reloading, with no download', () async {
    start(UpdateChannel.web);
    await cubit.checkForUpdate();

    await cubit.installUpdate();

    expect(repository.downloads, 0);
    expect(repository.applied, [null]);
  });

  test('the automatic-check switch is saved', () async {
    start(UpdateChannel.linux);

    await cubit.setAutomaticUpdateChecks(enabled: false);

    expect(cubit.state.automaticChecks, isFalse);
    expect(repository.automaticChecksEnabled, isFalse);
  });
}

class _FakeUpdateRepository implements UpdateRepository {
  _FakeUpdateRepository(this.channel);

  @override
  final UpdateChannel channel;

  UpdateRelease? latest;
  bool due = false;
  AppException? checkError;
  AppException? downloadError;
  AppException? applyError;
  int checks = 0;
  int downloads = 0;
  final List<String?> applied = [];

  @override
  bool automaticChecksEnabled = true;

  @override
  bool get isAutomaticCheckDue => due;

  @override
  Future<String> runningVersion() async => '1.1.2';

  @override
  Future<UpdateRelease?> findNewerRelease() async {
    if (!channel.checksForUpdates) return null;
    checks++;
    if (checkError case final error?) throw error;
    return latest;
  }

  @override
  Future<void> saveAutomaticChecksEnabled({required bool enabled}) async =>
      automaticChecksEnabled = enabled;

  @override
  Future<String> downloadUpdate(
    UpdateRelease release, {
    required void Function(double progress) onProgress,
  }) async {
    downloads++;
    onProgress(0.5);
    if (downloadError case final error?) throw error;
    onProgress(1);
    return '/tmp/setup.exe';
  }

  @override
  Future<void> applyUpdate({String? installerPath}) async {
    applied.add(installerPath);
    if (applyError case final error?) throw error;
  }
}
