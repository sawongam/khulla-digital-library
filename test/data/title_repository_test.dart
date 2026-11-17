// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/title/data/local_title_data_source.dart';
import 'package:khulla/features/catalog/title/data/title_repository_impl.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// Guards [TitleRepositoryImpl.removeTitle] when copies still exist.
void main() {
  late AppDatabase db;
  late TitleRepositoryImpl repository;

  setUp(() async {
    db = await openTestDatabase();
    repository = TitleRepositoryImpl(LocalTitleDataSource(db));
  });

  tearDown(() => closeTestDatabase(db));

  test('removeTitle with copies throws ConflictException', () async {
    final reference = await seedReferenceData(db);
    final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);

    expect(
      () => repository.removeTitle(seeded.titleId),
      throwsA(isA<ConflictException>()),
    );

    final title = await repository.findTitle(seeded.titleId);
    expect(title, isNotNull);
  });

  group('archiveTitle', () {
    test('archives live copies with the title and restore brings back only '
        'those', () async {
      final reference = await seedReferenceData(db);
      final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
      final earlier = DateTime(2020);
      // A second copy withdrawn on its own before the title was archived.
      final other = await seedTitleWithCopy(
        db,
        formatId: reference.formatId,
        barcode: 'TEST-002',
        title: 'Other',
      );
      await (db.update(db.copies)..where((c) => c.id.equals(other.copyId)))
          .write(CopiesCompanion(titleId: Value(seeded.titleId)));
      await (db.update(db.copies)..where((c) => c.id.equals(other.copyId)))
          .write(CopiesCompanion(archivedAt: Value(earlier)));

      await repository.archiveTitle(seeded.titleId);

      final archived = await repository.findTitle(seeded.titleId);
      expect(archived!.archivedAt, isNotNull);
      final copies = await db.select(db.copies).get();
      final live = copies.firstWhere((c) => c.id == seeded.copyId);
      expect(live.archivedAt, archived.archivedAt);
      final withdrawn = copies.firstWhere((c) => c.id == other.copyId);
      expect(withdrawn.archivedAt, earlier);

      await repository.restoreTitle(seeded.titleId);

      expect((await repository.findTitle(seeded.titleId))!.archivedAt, isNull);
      final after = await db.select(db.copies).get();
      expect(after.firstWhere((c) => c.id == seeded.copyId).archivedAt, isNull);
      expect(after.firstWhere((c) => c.id == other.copyId).archivedAt, earlier);
    });

    test('refuses while a copy is on loan', () async {
      final reference = await seedReferenceData(db);
      final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
      await (db.update(db.copies)..where((c) => c.id.equals(seeded.copyId)))
          .write(const CopiesCompanion(status: Value(CopyStatus.onLoan)));

      await expectLater(
        repository.archiveTitle(seeded.titleId),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.reason,
            'reason',
            AppErrorReason.titleHasCopiesOnLoan,
          ),
        ),
      );
      expect((await repository.findTitle(seeded.titleId))!.archivedAt, isNull);
    });
  });
}
