// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/members/domain/member_repository.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';
import 'package:khulla/features/members/presentation/cubit/member_state.dart';
import 'package:khulla/shared/models/load_status.dart';

/// The members list: search, filters, sort and pagination.
///
/// Page-scoped `@injectable` cubit that dies with the list. Delegates to
/// [MemberRepository]; [loadMembers] failures emit into [MemberState.error].
@injectable
class MemberCubit extends Cubit<MemberState> {
  MemberCubit(this._repository) : super(const MemberState());

  final MemberRepository _repository;

  /// Fetches the current page of members using [MemberState.query].
  Future<void> loadMembers() async {
    emit(
      state.copyWith(status: state.status.forCollectionFetch(), error: null),
    );
    try {
      final result = await _repository.findMembers(state.query);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          members: result.items,
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
    unawaited(loadMembers());
  }

  void withLoansChanged(bool value) {
    emit(
      state.copyWith(
        query: state.query.copyWith(withLoans: value, offset: 0),
      ),
    );
    unawaited(loadMembers());
  }

  void owesFinesChanged(bool value) {
    emit(
      state.copyWith(
        query: state.query.copyWith(owesFines: value, offset: 0),
      ),
    );
    unawaited(loadMembers());
  }

  void suspendedChanged(bool value) {
    emit(
      state.copyWith(
        query: state.query.copyWith(suspended: value, offset: 0),
      ),
    );
    unawaited(loadMembers());
  }

  void expiringChanged(bool value) {
    emit(
      state.copyWith(
        query: state.query.copyWith(expiring: value, offset: 0),
      ),
    );
    unawaited(loadMembers());
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
    unawaited(loadMembers());
  }

  void clearFilters() {
    emit(
      state.copyWith(
        query: MemberQuery(limit: state.query.limit),
      ),
    );
    unawaited(loadMembers());
  }

  void limitChanged(int limit) {
    if (state.query.limit == limit) return;
    emit(
      state.copyWith(
        query: state.query.copyWith(limit: limit, offset: 0),
      ),
    );
    unawaited(loadMembers());
  }

  void pageChanged(int page) {
    emit(
      state.copyWith(
        query: state.query.copyWith(
          offset: page * state.query.limit,
        ),
      ),
    );
    unawaited(loadMembers());
  }

  /// Suspends one member and reloads the list. Rethrows on failure.
  Future<void> suspendMember(String id) async {
    await _repository.suspendMember(id);
    if (isClosed) return;
    await loadMembers();
  }

  /// Clears suspension and reloads the list. Rethrows on failure.
  Future<void> unsuspendMember(String id) async {
    await _repository.unsuspendMember(id);
    if (isClosed) return;
    await loadMembers();
  }

  /// Archives one member and reloads the list. Rethrows on failure.
  Future<void> archiveMember(String id) async {
    await _repository.archiveMember(id);
    if (isClosed) return;
    await loadMembers();
  }

  /// Extends membership and reloads the list. Rethrows on failure.
  Future<void> renewMembership(String id) async {
    await _repository.renewMembership(id);
    if (isClosed) return;
    await loadMembers();
  }
}
