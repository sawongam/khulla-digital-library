// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';

/// Maps [TitleRow] to [Title] and back for drift writes.
///
/// Joined columns - format name and copy counts - are passed in from the data
/// source because they are not on the base row.
extension TitleRowMapper on TitleRow {
  Title toDomain({
    required String formatName,
    required int copyCount,
    required int availableCount,
    String? formatCode,
  }) => Title(
    id: id,
    title: title,
    author: author,
    isbn: isbn,
    publisher: publisher,
    publishedYear: publishedYear,
    edition: edition,
    language: language,
    pages: pages,
    description: description,
    shelf: shelf,
    formatId: formatId,
    formatName: formatName,
    formatCode: formatCode,
    lendable: lendable,
    replacementCost: replacementCost,
    createdAt: createdAt,
    updatedAt: updatedAt,
    archivedAt: archivedAt,
    copyCount: copyCount,
    availableCount: availableCount,
  );
}

extension TitleDomainMapper on Title {
  TitlesCompanion toCompanion() => TitlesCompanion(
    id: Value(id),
    title: Value(title),
    author: Value(author),
    isbn: Value(isbn),
    publisher: Value(publisher),
    publishedYear: Value(publishedYear),
    edition: Value(edition),
    pages: Value(pages),
    formatId: Value(formatId),
    language: Value(language),
    description: Value(description),
    shelf: Value(shelf),
    lendable: Value(lendable),
    replacementCost: Value(replacementCost),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    archivedAt: Value(archivedAt),
  );
}
