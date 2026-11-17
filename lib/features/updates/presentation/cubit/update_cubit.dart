// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/logging/app_logger.dart';
import 'package:khulla/features/updates/domain/update_repository.dart';
import 'package:khulla/features/updates/presentation/cubit/update_state.dart';
import 'package:khulla/features/updates/presentation/cubit/update_status.dart';

/// The app's own updates: the daily check, and the dialog's flow from
/// "is there one?" to handing over to it.
///
/// App-wide because the answer outlives the dialog - the account chip shows
/// a dot once an update is known, and a download keeps going when the
/// dialog is closed, so reopening it finds the progress bar where it was.
///
/// Every step reports failure through `state.error` rather than throwing:
/// the dialog is watching the state for the whole flow, and shows the
/// failure where the button that failed was, with a retry beside it.
@lazySingleton
class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit(this._repository)
    : super(
        UpdateState(
          channel: _repository.channel,
          automaticChecks: _repository.automaticChecksEnabled,
        ),
      );

  final UpdateRepository _repository;

  /// The check that runs on launch, at most once a day. A failure stays
  /// quiet - nobody asked, so nobody should be told the server was down.
  Future<void> checkForUpdateIfDue() async {
    if (state.isBusy || state.hasUpdate || !_repository.isAutomaticCheckDue) {
      return;
    }
    try {
      final release = await _repository.findNewerRelease();
      if (release == null || state.isBusy) return;
      emit(
        state.copyWith(
          status: UpdateStatus.available,
          release: release,
          error: null,
        ),
      );
    } on AppException catch (error) {
      AppLogger.warn(
        'Automatic update check failed.',
        source: 'UpdateCubit.checkForUpdateIfDue',
        error: error,
      );
    }
  }

  /// The check the dialog runs when it opens.
  ///
  /// A download under way, or an installer waiting to run, is kept rather
  /// than thrown away by asking again.
  Future<void> checkForUpdate() async {
    if (!state.channel.checksForUpdates ||
        state.isBusy ||
        state.status == UpdateStatus.readyToInstall) {
      return;
    }
    emit(
      state.copyWith(
        status: UpdateStatus.checking,
        release: null,
        installerPath: null,
        error: null,
      ),
    );
    final running = await _repository.runningVersion();
    try {
      final release = await _repository.findNewerRelease();
      emit(
        state.copyWith(
          status: release == null
              ? UpdateStatus.upToDate
              : UpdateStatus.available,
          runningVersion: running,
          release: release,
          error: null,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: UpdateStatus.failed,
          runningVersion: running,
          error: error,
        ),
      );
    }
  }

  /// Fetches and checks the installer for the release found.
  Future<void> downloadUpdate() async {
    final release = state.release;
    if (release == null || state.isBusy) return;

    emit(
      state.copyWith(
        status: UpdateStatus.downloading,
        progress: 0,
        installerPath: null,
        error: null,
      ),
    );
    try {
      final path = await _repository.downloadUpdate(
        release,
        // A whole percent at a time: the file arrives in hundreds of
        // chunks, and a rebuild for each is work nobody can see.
        onProgress: (progress) {
          if ((progress * 100).floor() > (state.progress * 100).floor()) {
            emit(state.copyWith(progress: progress));
          }
        },
      );
      emit(
        state.copyWith(
          status: UpdateStatus.readyToInstall,
          progress: 1,
          installerPath: path,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(status: UpdateStatus.failed, error: error));
    }
  }

  /// Backs up the catalogue and hands over to the new version. On success
  /// the app closes (Windows) or reloads (web), so nothing after it runs.
  Future<void> installUpdate() async {
    if (!state.channel.installsInApp || state.isBusy) return;
    emit(state.copyWith(status: UpdateStatus.installing, error: null));
    try {
      await _repository.applyUpdate(installerPath: state.installerPath);
    } on AppException catch (error) {
      emit(state.copyWith(status: UpdateStatus.failed, error: error));
    }
  }

  /// Retries whichever step failed: the check when no release was found
  /// yet, the download when the installer is still missing, otherwise the
  /// install.
  Future<void> retryUpdate() {
    if (!state.hasUpdate) return checkForUpdate();
    if (state.channel.downloadsInstaller && state.installerPath == null) {
      return downloadUpdate();
    }
    return installUpdate();
  }

  Future<void> setAutomaticUpdateChecks({required bool enabled}) async {
    if (state.automaticChecks == enabled) return;
    emit(state.copyWith(automaticChecks: enabled));
    await _repository.saveAutomaticChecksEnabled(enabled: enabled);
  }
}
