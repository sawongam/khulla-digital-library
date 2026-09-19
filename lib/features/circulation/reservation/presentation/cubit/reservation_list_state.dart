// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation_query.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'reservation_list_state.freezed.dart';

/// Reservations list query, page of results, and load status.
@freezed
abstract class ReservationListState with _$ReservationListState {
  const factory ReservationListState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(ReservationQuery()) ReservationQuery query,
    @Default(<Reservation>[]) List<Reservation> reservations,
    @Default(0) int totalCount,
    AppException? error,
  }) = _ReservationListState;

  const ReservationListState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
  bool get isEmpty => status.isLoaded && reservations.isEmpty;
}
