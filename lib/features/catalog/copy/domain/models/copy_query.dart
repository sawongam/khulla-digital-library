// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';

part 'copy_query.freezed.dart';

/// Filters and paging for the copy list.
///
/// [statuses] is empty for all statuses; [titleId] scopes to one work.
@freezed
abstract class CopyQuery with _$CopyQuery {
  const factory CopyQuery({
    @Default('') String search,
    String? titleId,
    @Default(<CopyStatus>{}) Set<CopyStatus> statuses,
    @Default('createdAt') String sortColumn,
    @Default(false) bool sortAscending,
    @Default(0) int offset,
    @Default(8) int limit,
  }) = _CopyQuery;
}

typedef CopyListResult = ({List<Copy> items, int totalCount});
