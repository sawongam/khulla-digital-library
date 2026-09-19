// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/cubit/member_type_state.dart';
import 'package:khulla/shared/domain/reference_data_repository.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Create, rename, tune and archive member categories.
///
/// Page-scoped `@injectable` cubit for the manage-categories modal. Reads
/// emit into [MemberTypeState.error]; writes emit and rethrow so the dialog
/// can toast without closing.
@injectable
class MemberTypeCubit extends Cubit<MemberTypeState> {
  MemberTypeCubit(this._repository) : super(const MemberTypeState());

  final ReferenceDataRepository _repository;

  /// Loads every category, active and archived, for the list.
  Future<void> loadTypes() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final types = await _repository.findAllMemberTypes();
      if (isClosed) return;
      emit(
        state.copyWith(status: LoadStatus.loaded, types: types, error: null),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Inserts a category, then reloads the list.
  Future<MemberType> addType(MemberType draft) async {
    try {
      final type = await _repository.addMemberType(draft);
      if (isClosed) return type;
      await _reloadTypes();
      return type;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Saves a category's name and rule overrides, then reloads the list.
  Future<MemberType> saveType(MemberType draft) async {
    try {
      final type = await _repository.saveMemberType(draft);
      if (isClosed) return type;
      await _reloadTypes();
      return type;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Archives a category so it leaves pickers, then reloads the list.
  Future<void> archiveType(String id) async {
    try {
      await _repository.removeMemberType(id);
      if (isClosed) return;
      await _reloadTypes();
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Brings an archived category back into pickers, then reloads the list.
  Future<void> unarchiveType(String id) async {
    try {
      await _repository.restoreMemberType(id);
      if (isClosed) return;
      await _reloadTypes();
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  Future<void> _reloadTypes() async {
    final types = await _repository.findAllMemberTypes();
    if (isClosed) return;
    emit(state.copyWith(status: LoadStatus.loaded, types: types, error: null));
  }
}
