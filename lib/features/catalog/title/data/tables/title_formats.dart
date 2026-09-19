// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';

/// Editable catalogue formats — book, journal, audiobook, and so on.
///
/// Seeded rows carry a stable [code] for icons and import/export; operator-
/// created rows leave it null and get a default glyph. Archiving hides a row
/// from pickers without invalidating titles that already reference it.
@DataClassName('TitleFormatRow')
class TitleFormats extends Table {
  TextColumn get id => text()();

  /// Stable machine id on seeded rows only — never changes when [name] is edited.
  TextColumn get code => text().nullable().unique()();

  /// What the operator sees in every dropdown.
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Order in pickers; lower comes first.
  IntColumn get sortOrder => integer()();

  /// Seeded rows cannot be hard-deleted — only archived and renamed.
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  /// When set, the row is hidden from pickers but still valid on existing titles.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
