// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/config/flavor.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/settings/data/backup_local_data_source.dart';
import 'package:khulla/features/settings/data/backup_platform_web.dart'
    as web_platform;

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// [BackupLocalDataSource] and the web backup functions against a real
/// database. Both operate purely through the `AppDatabase` connection - no
/// filesystem involved - so, unlike the native path, they run the same way
/// whether the underlying store is in-memory or on disk.
void main() {
  late AppDatabase db;
  late BackupLocalDataSource local;
  const config = AppConfig(
    flavor: Flavor.dev,
    databaseName: 'khulla_test',
    windowTitle: 'test',
  );

  setUp(() async {
    db = await openTestDatabase();
    local = BackupLocalDataSource(db);
  });

  tearDown(() => closeTestDatabase(db));

  test('wipeAllTables empties every table', () async {
    final reference = await seedReferenceData(db);
    await seedTitleWithCopy(db, formatId: reference.formatId);
    await seedMember(db, memberTypeId: reference.memberTypeId);

    expect(await db.select(db.titles).get(), isNotEmpty);
    expect(await db.select(db.members).get(), isNotEmpty);

    await local.wipeAllTables();

    expect(await db.select(db.titles).get(), isEmpty);
    expect(await db.select(db.copies).get(), isEmpty);
    expect(await db.select(db.members).get(), isEmpty);
  });

  test('web export/import round-trips a title and a member', () async {
    final reference = await seedReferenceData(db);
    final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
    final member = await seedMember(db, memberTypeId: reference.memberTypeId);

    final bytes = await web_platform.exportBackupBytes(db, config);
    await local.wipeAllTables();
    expect(await db.select(db.titles).get(), isEmpty);

    await web_platform.importBackupBytes(db, config, bytes);

    final titles = await db.select(db.titles).get();
    expect(titles, hasLength(1));
    expect(titles.single.id, seeded.titleId);

    final members = await db.select(db.members).get();
    expect(members, hasLength(1));
    expect(members.single.id, member.memberId);
  });

  test(
    'web import refuses a backup from a different schema version',
    () async {
      final tampered = Uint8List.fromList(
        utf8.encode(
          jsonEncode({'schemaVersion': -1, 'tables': <String, Object?>{}}),
        ),
      );

      expect(
        () => web_platform.importBackupBytes(db, config, tampered),
        throwsA(isA<InvalidInputException>()),
      );
    },
  );

  test('web import refuses a file that is not JSON', () async {
    final garbage = Uint8List.fromList(utf8.encode('not json at all'));

    expect(
      () => web_platform.importBackupBytes(db, config, garbage),
      throwsA(isA<InvalidInputException>()),
    );
  });
}
