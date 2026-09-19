// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/title/data/title_local_data_source.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';
import 'package:khulla/features/catalog/title/domain/title_repository.dart';
import 'package:uuid/uuid.dart';

/// [TitleRepository] over the local catalogue.
///
/// Owns id assignment and the guard that blocks [removeTitle] while copies
/// remain. Row mapping stays in [TitleLocalDataSource].
@LazySingleton(as: TitleRepository)
class TitleRepositoryImpl implements TitleRepository {
  TitleRepositoryImpl(this._dataSource);

  final TitleLocalDataSource _dataSource;
  static const Uuid _uuid = Uuid();

  @override
  Future<TitleListResult> findTitles(TitleQuery query) =>
      _dataSource.findTitles(query);

  @override
  Future<Title?> findTitle(String id) => _dataSource.findTitleById(id);

  @override
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
    String language = 'English',
    int? pages,
    String? description,
    String? shelf,
  }) async {
    final now = DateTime.now();
    final recordId = id ?? _uuid.v4();
    final existing = id == null ? null : await _dataSource.findTitleById(id);

    final draft = Title(
      id: recordId,
      title: title.trim(),
      author: author.trim(),
      formatId: formatId,
      formatName: existing?.formatName ?? '',
      formatCode: existing?.formatCode,
      isbn: isbn?.trim(),
      publisher: publisher?.trim(),
      publishedYear: publishedYear,
      edition: edition?.trim(),
      language: language.trim(),
      pages: pages,
      description: description?.trim(),
      shelf: shelf?.trim(),
      lendable: lendable,
      replacementCost: replacementCost,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      copyCount: existing?.copyCount ?? 0,
      availableCount: existing?.availableCount ?? 0,
    );

    if (existing == null) {
      return await _dataSource.insertTitle(draft);
    }
    return await _dataSource.updateTitle(draft);
  }

  @override
  Future<void> archiveTitle(String id) =>
      _dataSource.archiveTitle(id, DateTime.now());

  @override
  Future<void> removeTitle(String id) async {
    if (await _dataSource.hasDependentCopies(id)) {
      throw const ConflictException('Title has copies and cannot be deleted.');
    }
    await _dataSource.deleteTitle(id);
  }
}
