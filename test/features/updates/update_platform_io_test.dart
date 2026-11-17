// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/updates/data/update_platform_io.dart';
import 'package:khulla/features/updates/domain/models/update_download.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_database.dart';

/// The native half of the update: nothing runs a download that does not
/// match the manifest, and no update starts without a copy of the
/// catalogue.
void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('khulla-update-'));
  tearDown(() => temp.deleteSync(recursive: true));

  group('downloadInstaller', () {
    final bytes = List<int>.generate(200000, (i) => i % 251);

    UpdateDownload describe({String? sha, int? size}) => UpdateDownload(
      url: Uri.parse('https://example.com/v1/khulla-setup.exe'),
      sha256: sha ?? sha256.convert(bytes).toString(),
      sizeBytes: size ?? bytes.length,
    );

    MockClient serving(List<int> body, {int status = 200}) =>
        MockClient.streaming(
          (request, _) async => http.StreamedResponse(
            Stream.fromIterable([
              for (var i = 0; i < body.length; i += 65536)
                body.sublist(i, (i + 65536).clamp(0, body.length)),
            ]),
            status,
          ),
        );

    test('saves a file that matches, reporting progress up to 1', () async {
      final progress = <double>[];

      final path = await downloadInstaller(
        serving(bytes),
        describe(),
        onProgress: progress.add,
        directory: p.join(temp.path, 'dl'),
      );

      expect(File(path).readAsBytesSync(), bytes);
      expect(p.basename(path), 'khulla-setup.exe');
      expect(progress.last, 1.0);
      expect(progress, orderedEquals([...progress]..sort()));
    });

    test('deletes and refuses a file whose checksum does not match', () async {
      final folder = p.join(temp.path, 'dl');

      await expectLater(
        downloadInstaller(
          serving(bytes),
          describe(sha: 'b' * 64),
          onProgress: (_) {},
          directory: folder,
        ),
        throwsA(
          isA<StorageException>().having(
            (e) => e.reason,
            'reason',
            AppErrorReason.updateDownloadDamaged,
          ),
        ),
      );
      expect(Directory(folder).listSync(), isEmpty);
    });

    test('refuses a download cut short, or longer than promised', () async {
      for (final body in [
        bytes.sublist(0, 1000),
        [...bytes, 1, 2, 3],
      ]) {
        await expectLater(
          downloadInstaller(
            serving(body),
            describe(),
            onProgress: (_) {},
            directory: p.join(temp.path, 'dl'),
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.reason,
              'reason',
              AppErrorReason.updateDownloadDamaged,
            ),
          ),
        );
      }
    });

    test('a server error reads as updateDownloadFailed', () async {
      await expectLater(
        downloadInstaller(
          serving(const [], status: 404),
          describe(),
          onProgress: (_) {},
          directory: p.join(temp.path, 'dl'),
        ),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.reason,
            'reason',
            AppErrorReason.updateDownloadFailed,
          ),
        ),
      );
    });
  });

  test('installerArguments keeps the update where the install is', () {
    expect(
      installerArguments(perUser: true),
      containsAll(['/SILENT', '/UPDATE=1', '/CURRENTUSER']),
    );
    expect(installerArguments(perUser: false), contains('/ALLUSERS'));
    expect(installerArguments(perUser: false), isNot(contains('/CURRENTUSER')));
  });

  group('snapshotBeforeUpdate', () {
    late AppDatabase db;

    setUp(() async => db = await openTestDatabase());
    tearDown(() => closeTestDatabase(db));

    test('writes a readable copy into backups/ beside the catalogue', () async {
      final path = await snapshotBeforeUpdate(
        db,
        databasePath: p.join(temp.path, 'khulla.sqlite'),
        runningVersion: '1.1.2',
        now: DateTime(2026, 11, 17, 9, 5, 3),
      );

      expect(
        path,
        p.join(
          temp.path,
          'backups',
          'khulla-before-update-20261117-090503'
              '-v1.1.2.sqlite',
        ),
      );
      final header = File(path).openSync().readSync(15);
      expect(String.fromCharCodes(header), 'SQLite format 3');
    });

    test(
      "keeps the newest three of this catalogue, and no one else's",
      () async {
        final backups = Directory(p.join(temp.path, 'backups'))..createSync();
        final foreign = File(
          p.join(backups.path, 'khulla_dev-before-update-1.sqlite'),
        )..writeAsStringSync('dev');

        for (var day = 1; day <= 5; day++) {
          await snapshotBeforeUpdate(
            db,
            databasePath: p.join(temp.path, 'khulla.sqlite'),
            runningVersion: day == 5 ? '1.10.0' : '1.9.$day',
            now: DateTime(2026, 11, day),
          );
        }

        final kept =
            backups
                .listSync()
                .map((entry) => p.basename(entry.path))
                .where((name) => name.startsWith('khulla-'))
                .toList()
              ..sort();
        expect(kept, [
          'khulla-before-update-20261103-000000-v1.9.3.sqlite',
          'khulla-before-update-20261104-000000-v1.9.4.sqlite',
          'khulla-before-update-20261105-000000-v1.10.0.sqlite',
        ]);
        expect(foreign.existsSync(), isTrue);
      },
    );
  });
}
