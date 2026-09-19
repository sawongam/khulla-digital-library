// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
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
}
