// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/settings/domain/backup_repository.dart';
import 'package:khulla/features/settings/presentation/cubit/backup_state.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/features/users/domain/staff_repository.dart';
import 'package:khulla/shared/models/load_status.dart';

/// The backup screen: the info card, and the three actions on it.
///
/// `restoreBackup`/`eraseCatalogue` both end by restarting the app on
/// success — there is nothing further for this cubit to show, and it never
/// gets the chance to run again in this process.
@injectable
class BackupCubit extends Cubit<BackupState> {
  BackupCubit(this._repository, this._staff, this._auth)
    : super(const BackupState());

  final BackupRepository _repository;
  final StaffRepository _staff;
  final AuthCubit _auth;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final info = await _repository.describeBackup();
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.loaded, info: info));
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Returns true when a backup was actually written — false means the
  /// operator cancelled the save dialog. Rethrows on failure so the page can
  /// show it as a toast.
  Future<bool> exportBackup() async {
    emit(state.copyWith(isWorking: true, error: null));
    try {
      final exported = await _repository.exportBackup();
      if (isClosed) return exported;
      emit(state.copyWith(isWorking: false));
      if (exported) await load();
      return exported;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(isWorking: false, error: error));
      rethrow;
    } finally {
      if (!isClosed && state.isWorking) {
        emit(state.copyWith(isWorking: false));
      }
    }
  }

  /// Restarts the app on success and never returns to a running screen.
  /// Returns false when the operator cancelled the file picker.
  Future<bool> restoreBackup() async {
    emit(state.copyWith(isWorking: true, error: null));
    try {
      return await _repository.restoreBackup();
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(isWorking: false, error: error));
      rethrow;
    } finally {
      if (!isClosed && state.isWorking) {
        emit(state.copyWith(isWorking: false));
      }
    }
  }

  /// Re-authenticates the signed-in account before the erase may proceed.
  ///
  /// True when [password] verifies against the session's account. False
  /// refuses without saying why beyond the dialog's field error — and that
  /// includes a missing session or a disabled account: without a verified
  /// operator there is no erase. A database failure emits into state and
  /// rethrows for the dialog to answer with a toast.
  Future<bool> verifyErasePassword(String password) async {
    final email = _auth.state.staff?.email;
    if (email == null || email.isEmpty) return false;
    try {
      final staff = await _staff.signIn(email: email, password: password);
      if (isClosed) return false;
      return staff != null;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Restarts the app on success and never returns to a running screen.
  Future<void> eraseCatalogue() async {
    emit(state.copyWith(isWorking: true, error: null));
    try {
      await _repository.eraseCatalogue();
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(isWorking: false, error: error));
      rethrow;
    } finally {
      if (!isClosed && state.isWorking) {
        emit(state.copyWith(isWorking: false));
      }
    }
  }
}
