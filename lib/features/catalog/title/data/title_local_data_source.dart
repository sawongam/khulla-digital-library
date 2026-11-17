// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';

/// Drift access to the `titles` table and its list aggregates.
///
/// List reads join formats and count copies so each [Title] carries copy
/// counts. Search reads `titles_fts`, which triggers keep current.
abstract interface class TitleLocalDataSource {
  Future<TitleListResult> findTitles(TitleQuery query);

  Future<Title?> findTitleById(String id);

  Future<Title> insertTitle(Title title);

  /// Inserts [title] and its first [copies] in one transaction, so a copy
  /// that cannot be added leaves no half-made title behind. Copies with a
  /// blank barcode are numbered from the library's barcode sequence.
  Future<Title> insertTitleWithCopies(Title title, List<Copy> copies);

  Future<Title> updateTitle(Title title);

  Future<void> archiveTitle(String id, DateTime archivedAt);

  Future<void> restoreTitle(String id);

  Future<bool> hasDependentCopies(String titleId);

  Future<void> deleteTitle(String id);
}
