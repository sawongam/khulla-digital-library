// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/copy/domain/copy_repository.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy_query.dart';
import 'package:khulla/features/catalog/copy/presentation/cubit/copy_state.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/shared/models/load_status.dart';

/// The copies list: search, status filters, sort and pagination.
///
/// Page-scoped `@injectable` cubit. Delegates to [CopyRepository].
/// [loadCopies] failures emit into [CopyState.error]; [archiveCopy] rethrows.
@injectable
class CopyCubit extends Cubit<CopyState> {
  CopyCubit(this._repository) : super(const CopyState());

  final CopyRepository _repository;

  /// Fetches the current page of copies using [CopyState.query].
  Future<void> loadCopies() async {
    emit(
      state.copyWith(status: state.status.forCollectionFetch(), error: null),
    );
    try {
      final result = await _repository.findCopies(state.query);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          copies: result.items,
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
    unawaited(loadCopies());
  }

  void statusFilterChanged(CopyStatus status, bool selected) {
    final next = Set<CopyStatus>.from(state.query.statuses);
    if (selected) {
      next.add(status);
    } else {
      next.remove(status);
    }
    emit(
      state.copyWith(
        query: state.query.copyWith(statuses: next, offset: 0),
      ),
    );
    unawaited(loadCopies());
  }

  void sortChanged(String columnId, bool ascending) {
    emit(
      state.copyWith(
        query: state.query.copyWith(
          sortColumn: columnId,
          sortAscending: ascending,
          offset: 0,
        ),
      ),
    );
    unawaited(loadCopies());
  }

  void clearFilters() {
    emit(state.copyWith(query: CopyQuery(limit: state.query.limit)));
    unawaited(loadCopies());
  }

  void limitChanged(int limit) {
    if (state.query.limit == limit) return;
    emit(
      state.copyWith(
        query: state.query.copyWith(limit: limit, offset: 0),
      ),
    );
    unawaited(loadCopies());
  }

  void pageChanged(int page) {
    emit(
      state.copyWith(
        query: state.query.copyWith(
          offset: page * state.query.limit,
        ),
      ),
    );
    unawaited(loadCopies());
  }

  /// Soft-deletes a copy and reloads the list. Rethrows on failure.
  Future<void> archiveCopy(String id) async {
    await _repository.archiveCopy(id);
    if (isClosed) return;
    await loadCopies();
  }

  /// Marks a copy lost and reloads the list. Rethrows on failure.
  Future<void> markCopyLost(String id) async {
    await _repository.updateCopyStatus(id, status: CopyStatus.lost);
    if (isClosed) return;
    await loadCopies();
  }

  /// Marks a copy damaged and reloads the list. Rethrows on failure.
  Future<void> markCopyDamaged(String id) async {
    await _repository.updateCopyStatus(id, status: CopyStatus.damaged);
    if (isClosed) return;
    await loadCopies();
  }
}
