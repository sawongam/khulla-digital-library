// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/shared/domain/fine_status.dart';

part 'fine_query.freezed.dart';

/// Filters and paging for the fines ledger.
///
/// [outstandingOnly] keeps rows where assessed exceeds paid plus waived.
@freezed
abstract class FineQuery with _$FineQuery {
  const factory FineQuery({
    @Default('') String search,
    String? memberId,
    FineStatus? status,
    @Default(false) bool outstandingOnly,
    @Default('raisedAt') String sortColumn,
    @Default(false) bool sortAscending,
    @Default(0) int offset,
    @Default(50) int limit,
  }) = _FineQuery;
}

typedef FineListResult = ({List<Fine> items, int totalCount});
