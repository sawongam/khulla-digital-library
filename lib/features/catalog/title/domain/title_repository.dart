// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';

/// Catalogue works: list, load, save, archive and hard-delete.
///
/// [saveTitle] assigns ids and rebuilds search text; [removeTitle] refuses
/// when copies still exist. Archived rows stay out of list queries.
abstract interface class TitleRepository {
  Future<TitleListResult> findTitles(TitleQuery query);

  Future<Title?> findTitle(String id);

  Future<Title> saveTitle({
    required String title,
    required String author,
    required String formatId,
    required bool lendable,
    required Money replacementCost,
    String? id,
    String? isbn,
    String? publisher,
    int? publishedYear,
    String? edition,
    String language,
    int? pages,
    String? description,
    String? shelf,
  });

  Future<void> archiveTitle(String id);

  Future<void> removeTitle(String id);
}
