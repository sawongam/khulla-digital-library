// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';

part 'reservation_query.freezed.dart';

/// Filters and paging for the holds list.
///
/// [activeOnly] hides closed holds; queue order follows [sortColumn].
@freezed
abstract class ReservationQuery with _$ReservationQuery {
  const factory ReservationQuery({
    @Default('') String search,
    String? memberId,
    String? titleId,
    ReservationStatus? status,
    @Default(true) bool activeOnly,
    @Default('placedAt') String sortColumn,
    @Default(false) bool sortAscending,
    @Default(0) int offset,
    @Default(50) int limit,
  }) = _ReservationQuery;
}

typedef ReservationListResult = ({List<Reservation> items, int totalCount});
