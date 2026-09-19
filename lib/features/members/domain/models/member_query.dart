// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/features/members/domain/models/member.dart';

part 'member_query.freezed.dart';

/// Filters and paging for the member list.
///
/// Quick filters ([withLoans], [owesFines], [suspended], [expiring]) map to
/// SQL predicates on aggregates and expiry dates.
@freezed
abstract class MemberQuery with _$MemberQuery {
  const factory MemberQuery({
    @Default('') String search,
    @Default(false) bool withLoans,
    @Default(false) bool owesFines,
    @Default(false) bool suspended,
    @Default(false) bool expiring,
    @Default('createdAt') String sortColumn,
    @Default(false) bool sortAscending,
    @Default(0) int offset,
    @Default(8) int limit,
  }) = _MemberQuery;
}

typedef MemberListResult = ({List<Member> items, int totalCount});
