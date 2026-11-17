// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/copy/data/copy_repository_impl.dart';
import 'package:khulla/features/catalog/copy/data/local_copy_data_source.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy_query.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/title/data/local_title_data_source.dart';
import 'package:khulla/features/catalog/title/data/title_repository_impl.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// Barcode allocation, clash naming, copy edits, restore, and the atomic
/// title-with-copies write.
void main() {
  late AppDatabase db;
  late CopyRepositoryImpl copies;
  late TitleRepositoryImpl titles;
  late String formatId;

  setUp(() async {
    db = await openTestDatabase();
    copies = CopyRepositoryImpl(LocalCopyDataSource(db));
    titles = TitleRepositoryImpl(LocalTitleDataSource(db));
    formatId = (await seedReferenceData(db)).formatId;
    final now = DateTime.now();
    await db
        .into(db.librarySettings)
        .insert(
          LibrarySettingsCompanion.insert(
            name: 'Test library',
            currency: 'NPR',
            currencyName: 'Rupee',
            currencySymbol: 'Rs',
            barcodePrefix: const Value('KDL'),
            barcodeNextValue: const Value(1),
            createdAt: now,
            updatedAt: Value(now),
          ),
        );
  });

  tearDown(() => closeTestDatabase(db));

  Future<String> seedTitle(String name, String barcode) async =>
      (await seedTitleWithCopy(
        db,
        formatId: formatId,
        title: name,
        barcode: barcode,
      )).titleId;

  test('auto barcode skips numbers held by live or archived copies', () async {
    final titleId = await seedTitle('Matilda', 'KDL1');
    final archived = await copies.addCopy(
      titleId: titleId,
      titleName: 'Matilda',
      barcode: 'KDL2',
    );
    await copies.archiveCopy(archived.id);

    final added = await copies.addCopy(titleId: titleId, titleName: 'Matilda');
    expect(added.barcode, 'KDL3');
    final next = await copies.addCopy(titleId: titleId, titleName: 'Matilda');
    expect(next.barcode, 'KDL4');
  });

  test('hand-typed clash names the holder, archived or not', () async {
    final titleId = await seedTitle('Matilda', 'KDL104');

    await expectLater(
      copies.addCopy(titleId: titleId, titleName: 'Matilda', barcode: 'KDL104'),
      throwsA(
        isA<DuplicateRecordException>()
            .having((e) => e.reason, 'reason', AppErrorReason.barcodeInUse)
            .having((e) => e.args, 'args', ['KDL104', 'Matilda']),
      ),
    );

    final held = (await copies.findCopyByBarcode('KDL104'))!;
    await copies.archiveCopy(held.id);
    await expectLater(
      copies.addCopy(titleId: titleId, titleName: 'Matilda', barcode: 'KDL104'),
      throwsA(
        isA<DuplicateRecordException>().having(
          (e) => e.reason,
          'reason',
          AppErrorReason.barcodeInUseByArchivedCopy,
        ),
      ),
    );
  });

  test('updateCopyDetails edits, trims, and refuses a taken barcode', () async {
    final titleId = await seedTitle('Matilda', 'KDL1');
    final other = await copies.addCopy(
      titleId: titleId,
      titleName: 'Matilda',
      barcode: 'KDL2',
    );
    final mine = (await copies.findCopyByBarcode('KDL1'))!;

    final saved = await copies.updateCopyDetails(
      mine.id,
      barcode: ' KDL9 ',
      shelf: ' A1 ',
      notes: ' torn cover ',
    );
    expect(saved.barcode, 'KDL9');
    expect(saved.shelf, 'A1');
    expect(saved.notes, 'torn cover');

    // Keeping its own barcode is not a clash.
    await copies.updateCopyDetails(mine.id, barcode: 'KDL9', shelf: '');
    await expectLater(
      copies.updateCopyDetails(mine.id, barcode: other.barcode, shelf: ''),
      throwsA(isA<DuplicateRecordException>()),
    );
    await expectLater(
      copies.updateCopyDetails(mine.id, barcode: '  ', shelf: ''),
      throwsA(isA<InvalidInputException>()),
    );
  });

  test('restoreCopy refuses while the title is archived', () async {
    final titleId = await seedTitle('Matilda', 'KDL1');
    final copy = (await copies.findCopyByBarcode('KDL1'))!;
    await copies.archiveCopy(copy.id);
    await titles.archiveTitle(titleId);

    await expectLater(
      copies.restoreCopy(copy.id),
      throwsA(
        isA<ConflictException>().having(
          (e) => e.reason,
          'reason',
          AppErrorReason.restoreTitleFirst,
        ),
      ),
    );

    final before = await copies.findCopies(const CopyQuery(archived: true));
    expect(before.items, hasLength(1));

    await titles.restoreTitle(titleId);
    await copies.restoreCopy(copy.id);
    final after = await copies.findCopies(const CopyQuery(archived: true));
    expect(after.items, isEmpty);
    expect(await copies.findCopyByBarcode('KDL1'), isNotNull);
  });

  test('a failing initial copy leaves no title behind', () async {
    final source = LocalTitleDataSource(db);
    final now = DateTime.now();
    Copy copyOf(String id) => Copy(
      id: id,
      barcode: 'DUP',
      titleId: 'broken',
      titleName: 'Broken',
      shelf: '',
      status: CopyStatus.available,
      acquiredAt: now,
    );
    final title = Title(
      id: 'broken',
      title: 'Broken',
      author: 'A',
      formatId: formatId,
      formatName: '',
      lendable: true,
      replacementCost: Money.zero,
      createdAt: now,
      updatedAt: now,
      copyCount: 0,
      availableCount: 0,
    );

    await expectLater(
      source.insertTitleWithCopies(title, [copyOf('c1'), copyOf('c2')]),
      throwsA(isA<DuplicateRecordException>()),
    );
    expect(await source.findTitleById('broken'), isNull);
    expect(await copies.findCopyByBarcode('DUP'), isNull);
  });

  test('saveTitle creates the title with its initial copies', () async {
    final saved = await titles.saveTitle(
      title: 'Fine',
      author: 'A',
      formatId: formatId,
      lendable: true,
      replacementCost: Money.zero,
      initialCopies: 2,
    );
    expect(saved.copyCount, 2);
  });
}
