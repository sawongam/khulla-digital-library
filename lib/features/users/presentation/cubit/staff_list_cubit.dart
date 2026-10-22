// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';
import 'package:khulla/features/users/domain/user_status.dart';
import 'package:khulla/features/users/presentation/cubit/staff_list_state.dart';
import 'package:khulla/shared/models/load_status.dart';

/// The staff register: every account, and the enable/disable action a row
/// menu triggers directly without opening the editor.
@injectable
class StaffListCubit extends Cubit<StaffListState> {
  StaffListCubit(this._staff) : super(const StaffListState());

  final StaffRepository _staff;

  Future<void> loadStaff() async {
    emit(
      state.copyWith(status: state.status.forCollectionFetch(), error: null),
    );
    try {
      final staff = await _staff.findAllStaff();
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.loaded, staff: staff));
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Enables or disables [id]. Rethrows so the row menu can show the failure
  /// as a toast - the lockout and self-disable rules live in the repository,
  /// not here, so there is exactly one place that enforces them.
  Future<void> setStatus(String id, UserStatus status) async {
    try {
      await _staff.setStaffStatus(id: id, status: status);
      await loadStaff();
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }
}
