// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/shared/domain/reference_data_repository.dart';
import 'package:khulla/shared/models/load_status.dart';
import 'package:khulla/shared/presentation/cubit/reference_data_state.dart';

/// App-wide cache of catalogue reference rows: title formats and member types.
///
/// Forms and filters read from here so every screen sees the same active
/// options without re-querying on each open. A [lazySingleton] — it outlives
/// any one page and is never closed.
///
/// Delegates to [ReferenceDataRepository]. Reads emit failures into
/// [ReferenceDataState.error]; [refreshFormats] and [refreshMemberTypes]
/// patch one list after a write elsewhere without a full reload.
@lazySingleton
class ReferenceDataCubit extends Cubit<ReferenceDataState> {
  ReferenceDataCubit(this._repository) : super(const ReferenceDataState());

  final ReferenceDataRepository _repository;

  /// Loads both format and member-type lists for the first paint.
  ///
  /// A failure is emitted into state and swallowed — the shell can show
  /// [ReferenceDataState.error] while the operator keeps working elsewhere.
  Future<void> loadReferenceData() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final formats = await _repository.findActiveFormats();
      final memberTypes = await _repository.findActiveMemberTypes();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          formats: formats,
          memberTypes: memberTypes,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Re-fetches formats after a settings change without resetting member types.
  Future<void> refreshFormats() async {
    final formats = await _repository.findActiveFormats();
    if (isClosed) return;
    emit(state.copyWith(formats: formats));
  }

  /// Re-fetches member types after a settings change without resetting formats.
  Future<void> refreshMemberTypes() async {
    final memberTypes = await _repository.findActiveMemberTypes();
    if (isClosed) return;
    emit(state.copyWith(memberTypes: memberTypes));
  }
}
