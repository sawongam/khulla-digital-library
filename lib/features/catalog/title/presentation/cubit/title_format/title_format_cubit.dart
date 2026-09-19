// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title_format/title_format_state.dart';
import 'package:khulla/shared/domain/reference_data_repository.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Create, rename and archive catalogue formats.
///
/// Page-scoped `@injectable` cubit for the manage-formats modal. Reads emit
/// into [TitleFormatState.error]; writes emit and rethrow so the dialog can
/// toast without closing.
@injectable
class TitleFormatCubit extends Cubit<TitleFormatState> {
  TitleFormatCubit(this._repository) : super(const TitleFormatState());

  final ReferenceDataRepository _repository;

  /// Loads active formats for the list.
  Future<void> loadFormats() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final formats = await _repository.findActiveFormats();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          formats: formats,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Inserts a format, then reloads the list.
  Future<TitleFormat> addFormat(String name) async {
    try {
      final format = await _repository.addFormat(name);
      if (isClosed) return format;
      await _reloadFormats();
      return format;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Renames a format, then reloads the list.
  Future<TitleFormat> saveFormat({
    required String id,
    required String name,
  }) async {
    try {
      final format = await _repository.saveFormat(id: id, name: name);
      if (isClosed) return format;
      await _reloadFormats();
      return format;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Archives a format so it leaves pickers, then reloads the list.
  Future<void> removeFormat(String id) async {
    try {
      await _repository.removeFormat(id);
      if (isClosed) return;
      await _reloadFormats();
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  Future<void> _reloadFormats() async {
    final formats = await _repository.findActiveFormats();
    if (isClosed) return;
    emit(
      state.copyWith(
        status: LoadStatus.loaded,
        formats: formats,
        error: null,
      ),
    );
  }
}
