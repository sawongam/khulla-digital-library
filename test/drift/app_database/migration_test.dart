// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

// dart format width=80
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/catalog/title/data/local_title_data_source.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';
import 'package:khulla/features/members/data/local_member_data_source.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase.connect(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('migration from v1 to v2 does not corrupt data', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.connect,
      createItems: (batch, oldDb) {},
      validateItems: (newDb) async {},
    );
  });

  test('v11 to v12 indexes existing rows for search and reconciles holds '
      'whose status and closed_at disagree', () async {
    final schema = await verifier.schemaAt(11);
    // Search now indexes the richer profile (barcode, municipality, …)
    // added in v14. Verifying against the latest schema ensures the data
    // seeded on the old shape survives the full chain of FTS rebuilds.
    const at = '2026-09-01T10:00:00.000Z';
    schema.rawDatabase
      ..execute(
        'INSERT INTO title_formats (id, name, sort_order, created_at) '
        "VALUES ('f1', 'Book', 0, '$at')",
      )
      ..execute(
        'INSERT INTO member_types (id, name, sort_order, created_at) '
        "VALUES ('mt1', 'Student', 0, '$at')",
      )
      ..execute(
        'INSERT INTO titles '
        '(id, title, author, format_id, search_text, created_at, updated_at) '
        "VALUES ('t1', 'मुना मदन', 'लक्ष्मीप्रसाद देवकोटा', 'f1', "
        "'मुना मदन लक्ष्मीप्रसाद देवकोटा', '$at', '$at')",
      )
      ..execute(
        'INSERT INTO members (id, card_number, full_name, member_type_id, '
        'joined_at, search_text, created_at, updated_at) '
        "VALUES ('m1', 'KH-000123', 'Sita Sharma', 'mt1', '$at', "
        "'sita sharma kh-000123', '$at', '$at')",
      )
      // Closed by status, still open by date.
      ..execute(
        'INSERT INTO reservations (id, title_id, member_id, placed_at, '
        'status, created_at, updated_at) '
        "VALUES ('r1', 't1', 'm1', '$at', 'fulfilled', '$at', '$at')",
      )
      // Closed by date, still open by status.
      ..execute(
        'INSERT INTO reservations (id, title_id, member_id, placed_at, '
        'status, closed_at, created_at, updated_at) '
        "VALUES ('r2', 't1', 'm1', '$at', 'waiting', '$at', '$at', '$at')",
      );

    final db = AppDatabase.connect(schema.newConnection());
    await verifier.migrateAndValidate(db, 14);

    final titles = await LocalTitleDataSource(
      db,
    ).findTitles(const TitleQuery(search: 'देवको'));
    expect([for (final title in titles.items) title.id], ['t1']);

    final members = await LocalMemberDataSource(
      db,
    ).findMembers(const MemberQuery(search: '0123'));
    expect([for (final member in members.items) member.id], ['m1']);

    final holds = await db
        .customSelect(
          'SELECT id, status, closed_at FROM reservations ORDER BY id',
        )
        .get();
    expect(
      [
        for (final hold in holds)
          (
            hold.read<String>('id'),
            hold.read<String>('status'),
            hold.readNullable<String>('closed_at'),
          ),
      ],
      [('r1', 'fulfilled', at), ('r2', 'cancelled', at)],
    );

    await db.close();
  });
}
