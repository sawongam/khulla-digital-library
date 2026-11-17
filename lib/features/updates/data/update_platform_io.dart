// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/config/app_version.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/database_platform.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/logging/app_logger.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/domain/models/update_download.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String _source = 'UpdatePlatformIo';

/// How long to wait for the server to start answering, and then for each
/// next piece of the file. A slow line still finishes; a dead one does not
/// hang the dialog forever.
const Duration _connectTimeout = Duration(seconds: 30);
const Duration _idleTimeout = Duration(seconds: 60);

/// How many pre-update snapshots of each catalogue are kept.
const int _snapshotsKept = 3;

/// The package name Android records for an install from Google Play.
const String _playStore = 'com.android.vending';

/// How this install is updated, read from where it is running.
///
/// The Inno Setup installer leaves `unins000.exe` beside `khulla.exe`; the
/// portable zip does not. That file is the whole difference between an
/// install that can run the next installer over itself and a folder that
/// might be on a USB stick.
///
/// On Android, the system records which app installed this one: Play, or a
/// browser or file manager for the APK from the release page.
Future<UpdateChannel> detectUpdateChannel() async {
  if (Platform.isWindows) {
    final folder = p.dirname(Platform.resolvedExecutable);
    return File(p.join(folder, 'unins000.exe')).existsSync()
        ? UpdateChannel.windowsInstaller
        : UpdateChannel.windowsPortable;
  }
  if (Platform.isLinux) return UpdateChannel.linux;
  if (Platform.isAndroid) {
    return await AppVersion.installerStore() == _playStore
        ? UpdateChannel.googlePlay
        : UpdateChannel.androidApk;
  }
  return UpdateChannel.unsupported;
}

/// Downloads [download] into [directory] (a fresh folder under the system
/// temp directory by default) and checks it, resolving to the file's path.
///
/// The SHA-256 and the length are computed as the bytes arrive and compared
/// with the manifest's before this returns. A file that does not match is
/// deleted and refused with `updateDownloadDamaged` - nothing ever runs a
/// download that was cut short or altered on the way.
///
/// A file saved by this app, rather than a browser, carries no
/// mark-of-the-web, so Windows SmartScreen does not stop the installer.
Future<String> downloadInstaller(
  http.Client client,
  UpdateDownload download, {
  required void Function(double progress) onProgress,
  String? directory,
}) async {
  final folder = Directory(
    directory ?? p.join((await getTemporaryDirectory()).path, 'khulla-update'),
  );
  final target = File(p.join(folder.path, download.fileName));

  final http.StreamedResponse response;
  try {
    // Last attempt's leftovers go first, so the folder never fills up.
    if (folder.existsSync()) await folder.delete(recursive: true);
    await folder.create(recursive: true);
    response = await client
        .send(http.Request('GET', download.url))
        .timeout(_connectTimeout);
  } on FileSystemException {
    throw const StorageException.because(AppErrorReason.updateDownloadFailed);
  } on Object {
    throw const NetworkException.because(AppErrorReason.updateDownloadFailed);
  }
  if (response.statusCode != 200) {
    throw const NetworkException.because(AppErrorReason.updateDownloadFailed);
  }

  final digest = _DigestSink();
  final hasher = sha256.startChunkedConversion(digest);
  final sink = target.openWrite();
  var received = 0;
  try {
    await for (final chunk in response.stream.timeout(_idleTimeout)) {
      received += chunk.length;
      if (received > download.sizeBytes) {
        throw const StorageException.because(
          AppErrorReason.updateDownloadDamaged,
        );
      }
      sink.add(chunk);
      hasher.add(chunk);
      onProgress(received / download.sizeBytes);
    }
    await sink.flush();
  } on Object catch (error) {
    await _closeQuietly(sink);
    await _deleteQuietly(target);
    if (error is AppException) rethrow;
    if (error is FileSystemException) {
      throw const StorageException.because(
        AppErrorReason.updateDownloadFailed,
      );
    }
    throw const NetworkException.because(AppErrorReason.updateDownloadFailed);
  }
  await _closeQuietly(sink);
  hasher.close();

  if (received != download.sizeBytes ||
      digest.value.toString() != download.sha256) {
    await _deleteQuietly(target);
    throw const StorageException.because(AppErrorReason.updateDownloadDamaged);
  }
  return target.path;
}

/// Backs up the catalogue, starts the installer at [installerPath], closes
/// the database and ends the process. The installer reopens the app when it
/// is done (`[Run]` in `windows/installer.iss`).
///
/// Ordered so that every failure leaves this app running as it was: the
/// snapshot is taken first, and the database is closed only once the
/// installer has actually started. Restart Manager (`CloseApplications`)
/// would close a straggling window anyway; exiting first keeps that from
/// being needed.
Future<void> handOverToUpdate(
  AppDatabase db,
  AppConfig config, {
  required String? installerPath,
  required String runningVersion,
}) async {
  if (installerPath == null || !Platform.isWindows) {
    throw const StorageException.because(AppErrorReason.updateInstallFailed);
  }

  await snapshotBeforeUpdate(
    db,
    databasePath: await resolveDatabasePath(config.databaseName),
    runningVersion: runningVersion,
    now: DateTime.now(),
  );

  try {
    await Process.start(
      installerPath,
      installerArguments(perUser: _isPerUserInstall()),
      mode: ProcessStartMode.detached,
    );
  } on ProcessException catch (error, stackTrace) {
    AppLogger.error(
      error,
      stackTrace: stackTrace,
      source: '$_source.handOverToUpdate',
    );
    throw const StorageException.because(AppErrorReason.updateInstallFailed);
  }

  await db.dispose();
  exit(0);
}

/// What the installer is started with.
///
/// `/SILENT` shows Inno Setup's progress window and nothing else - no
/// wizard to click through, but not so silent that the operator thinks the
/// app crashed. `/UPDATE=1` is this app's own flag: it is what tells the
/// installer to reopen Khulla afterwards, so an administrator deploying
/// silently by hand does not get the app popping up.
///
/// [perUser] keeps the update in the same place as the install. The
/// installer offers per-user (the default) or all users; run silently
/// without saying which, it would pick per-user and leave an all-users
/// install beside a second copy.
@visibleForTesting
List<String> installerArguments({required bool perUser}) => [
  '/SILENT',
  '/SUPPRESSMSGBOXES',
  '/NORESTART',
  '/SP-',
  '/UPDATE=1',
  if (perUser) '/CURRENTUSER' else '/ALLUSERS',
];

/// Takes a `VACUUM INTO` copy of the catalogue into `backups/` beside it,
/// named for when it was taken and the version it came from, and keeps the
/// newest
/// [_snapshotsKept] of them.
///
/// The new version migrates the catalogue on first open. The migrations are
/// tested, but this app holds a library's only copy of its records - so an
/// update never runs without a copy the operator can restore from Settings
/// → Backup. If the copy cannot be taken, the update does not start.
@visibleForTesting
Future<String> snapshotBeforeUpdate(
  AppDatabase db, {
  required String databasePath,
  required String runningVersion,
  required DateTime now,
}) async {
  final folder = Directory(p.join(p.dirname(databasePath), 'backups'));
  final prefix = '${p.basenameWithoutExtension(databasePath)}-before-update-';
  final stamp =
      '${now.year}${_two(now.month)}${_two(now.day)}-'
      '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
  // Stamp before version, so sorting the names sorts them by age - `1.10.0`
  // would sort before `1.9.0` the other way round.
  final target = p.join(folder.path, '$prefix$stamp-v$runningVersion.sqlite');

  try {
    await folder.create(recursive: true);
  } on FileSystemException {
    throw const StorageException.because(AppErrorReason.updateInstallFailed);
  }
  await guardDatabase(
    () => db.customStatement('VACUUM INTO ?', [target]),
    source: '$_source.snapshotBeforeUpdate',
  );

  final snapshots =
      folder
          .listSync()
          .whereType<File>()
          .where((file) => p.basename(file.path).startsWith(prefix))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
  for (final stale in snapshots.skip(_snapshotsKept)) {
    await _deleteQuietly(stale);
  }
  return target;
}

/// Whether `khulla.exe` runs from under `%LOCALAPPDATA%`, where the
/// per-user installer puts it.
bool _isPerUserInstall() {
  final local = Platform.environment['LOCALAPPDATA'];
  if (local == null || local.isEmpty) return true;
  return p.isWithin(local, Platform.resolvedExecutable);
}

String _two(int value) => value.toString().padLeft(2, '0');

Future<void> _closeQuietly(IOSink sink) async {
  try {
    await sink.close();
  } on Object {
    // Already closed, or the disk went away - the file is deleted next.
  }
}

Future<void> _deleteQuietly(File file) async {
  try {
    if (file.existsSync()) await file.delete();
  } on FileSystemException {
    // A leftover in the temp folder; the next download clears it.
  }
}

/// Receives the one [Digest] a chunked SHA-256 produces when it is closed.
class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
