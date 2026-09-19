// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/converters/money_converter.dart';
import 'package:khulla/features/catalog/title/data/tables/title_formats.dart';

/// One work in the catalogue.
///
/// Searched through `titles_fts` (`titles_fts.drift`), which triggers on this
/// table keep current - there is no search column to write by hand.
@DataClassName('TitleRow')
@TableIndex(name: 'titles_format', columns: {#formatId})
@TableIndex.sql(
  'CREATE INDEX titles_isbn ON titles (isbn) WHERE isbn IS NOT NULL',
)
@TableIndex(name: 'titles_sort', columns: {#title})
class Titles extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withLength(min: 1, max: 300)();

  /// Plain text for now - no authors table (see plan §1.11).
  TextColumn get author => text().withLength(max: 200)();

  TextColumn get isbn => text().nullable().withLength(max: 20)();

  TextColumn get publisher => text().nullable().withLength(max: 200)();

  IntColumn get publishedYear => integer().nullable()();

  TextColumn get edition => text().nullable().withLength(max: 80)();

  IntColumn get pages => integer().nullable()();

  TextColumn get formatId =>
      text().references(TitleFormats, #id, onDelete: KeyAction.restrict)();

  TextColumn get language => text().withDefault(const Constant('English'))();

  TextColumn get description => text().nullable()();

  TextColumn get shelf => text().nullable().withLength(max: 60)();

  BoolColumn get lendable => boolean().withDefault(const Constant(true))();

  IntColumn get replacementCost =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (published_year IS NULL OR (published_year >= 1000 AND published_year <= 2200))',
    'CHECK (pages IS NULL OR pages > 0)',
  ];
}
