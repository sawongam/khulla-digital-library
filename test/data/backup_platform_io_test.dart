// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/settings/data/backup_platform_io.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../helpers/catalog_fixtures.dart';

/// The native backup path against real files: export through `VACUUM INTO`,
/// and a restore that validates before it touches anything and swaps the
/// file in whole.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('khulla_backup_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppDatabase> openAt(String path) async {
    final db = AppDatabase.connect(NativeDatabase(File(path)));
    await db.warmUp();
    return db;
  }

  Future<List<String>> titlesAt(String path) async {
    final db = await openAt(path);
    try {
      return [for (final row in await db.select(db.titles).get()) row.title];
    } finally {
      await db.close();
    }
  }

  /// A catalogue at [name] holding one title called [title], exported.
  Future<Uint8List> backupHolding(String name, String title) async {
    final path = p.join(dir.path, name);
    final db = await openAt(path);
    final reference = await seedReferenceData(db);
    await seedTitleWithCopy(db, formatId: reference.formatId, title: title);
    final bytes = await exportDatabaseSnapshot(db, databasePath: path);
    await db.close();
    return bytes;
  }

  test('export is a complete SQLite file at this schema version', () async {
    final bytes = await backupHolding('source.sqlite', 'Muna Madan');

    final copy = p.join(dir.path, 'copy.sqlite');
    File(copy).writeAsBytesSync(bytes);

    final memory = AppDatabase.connect(NativeDatabase.memory());
    final expectedVersion = memory.schemaVersion;
    await memory.close();
    final raw = sqlite3.open(copy);
    expect(raw.userVersion, expectedVersion);
    raw.close();
    expect(await titlesAt(copy), ['Muna Madan']);
    expect(
      dir.listSync().where((entry) => entry.path.contains('.export-')),
      isEmpty,
    );
  });

  group('restore', () {
    late String livePath;
    late AppDatabase live;

    setUp(() async {
      livePath = p.join(dir.path, 'live.sqlite');
      live = await openAt(livePath);
      final reference = await seedReferenceData(live);
      await seedTitleWithCopy(
        live,
        formatId: reference.formatId,
        title: 'Before',
      );
    });

    test('replaces the catalogue and keeps the old one beside it', () async {
      final backup = await backupHolding('other.sqlite', 'After');

      await replaceDatabaseFile(live, backup, databasePath: livePath);

      expect(await titlesAt(livePath), ['After']);
      expect(await titlesAt('$livePath$preRestoreSuffix'), ['Before']);
      expect(File('$livePath.restore-incoming').existsSync(), isFalse);
    });

    Future<void> expectRefused(Uint8List bytes, AppErrorReason? reason) async {
      await expectLater(
        replaceDatabaseFile(live, bytes, databasePath: livePath),
        throwsA(
          isA<InvalidInputException>().having(
            (error) => error.reason,
            'reason',
            reason ?? anything,
          ),
        ),
      );
      // Refused before anything was touched: the live connection still
      // answers, and the catalogue is still the old one.
      expect(
        [for (final row in await live.select(live.titles).get()) row.title],
        ['Before'],
      );
      expect(File('$livePath.restore-incoming').existsSync(), isFalse);
      expect(File('$livePath$preRestoreSuffix').existsSync(), isFalse);
    }

    test('refuses a file that is not SQLite', () async {
      await expectRefused(
        Uint8List.fromList('not a database'.codeUnits),
        AppErrorReason.notABackup,
      );
    });

    test('refuses a SQLite file that is not a Khulla catalogue', () async {
      final path = p.join(dir.path, 'unrelated.sqlite');
      sqlite3.open(path)
        ..execute('CREATE TABLE notes (body TEXT)')
        ..close();

      await expectRefused(
        File(path).readAsBytesSync(),
        AppErrorReason.notABackup,
      );
    });

    test('refuses a backup made by a newer build', () async {
      final path = p.join(dir.path, 'newer.sqlite');
      final bytes = await backupHolding('newer-source.sqlite', 'Future');
      File(path).writeAsBytesSync(bytes);
      final raw = sqlite3.open(path);
      raw.userVersion = raw.userVersion + 1;
      raw.close();

      await expectRefused(
        File(path).readAsBytesSync(),
        AppErrorReason.backupFromNewerVersion,
      );
    });

    test('refuses a damaged backup', () async {
      final bytes = await backupHolding('damaged-source.sqlite', 'Torn');
      // Scribble over everything after the first page, header intact, so
      // the file still claims to be SQLite but its pages are garbage.
      for (var i = 4096; i < bytes.length; i++) {
        bytes[i] = 0x5A;
      }

      await expectRefused(bytes, null);
    });

    tearDown(() async {
      try {
        await live.close();
      } on Object {
        // A successful restore already closed it.
      }
    });
  });
}
