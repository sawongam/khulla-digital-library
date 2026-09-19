// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation_query.dart';
import 'package:khulla/features/circulation/reservation/presentation/cubit/reservation_list_state.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Holds and reservations list with search and status filters.
///
/// Page-scoped `@injectable` cubit backed by [CirculationRepository].
/// [loadReservations] failures emit into [ReservationListState.error].
@injectable
class ReservationListCubit extends Cubit<ReservationListState> {
  ReservationListCubit(this._repository) : super(const ReservationListState());

  final CirculationRepository _repository;

  /// Fetches the current page of reservations using [ReservationListState.query].
  Future<void> loadReservations() async {
    emit(
      state.copyWith(status: state.status.forCollectionFetch(), error: null),
    );
    try {
      final result = await _repository.findReservations(state.query);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          reservations: result.items,
          totalCount: result.totalCount,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  void searchChanged(String value) {
    emit(
      state.copyWith(
        query: state.query.copyWith(search: value, offset: 0),
      ),
    );
    unawaited(loadReservations());
  }

  void statusFilterChanged(ReservationStatus? status) {
    emit(
      state.copyWith(
        query: state.query.copyWith(status: status, offset: 0),
      ),
    );
    unawaited(loadReservations());
  }

  void clearFilters() {
    emit(
      state.copyWith(
        query: ReservationQuery(limit: state.query.limit),
      ),
    );
    unawaited(loadReservations());
  }

  void limitChanged(int limit) {
    if (state.query.limit == limit) return;
    emit(
      state.copyWith(
        query: state.query.copyWith(limit: limit, offset: 0),
      ),
    );
    unawaited(loadReservations());
  }

  /// Cancels one hold and reloads the list. Rethrows on failure.
  Future<void> cancelHold(String reservationId) async {
    await _repository.cancelHold(reservationId);
    if (isClosed) return;
    await loadReservations();
  }

  /// Assigns an available copy and marks a waiting hold ready. Rethrows on failure.
  Future<void> markHoldReady(String reservationId) async {
    await _repository.markHoldReady(reservationId);
    if (isClosed) return;
    await loadReservations();
  }
}
