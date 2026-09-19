// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/settings/domain/models/backup_info.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'backup_state.freezed.dart';

@freezed
abstract class BackupState with _$BackupState {
  const factory BackupState({
    @Default(LoadStatus.initial) LoadStatus status,
    BackupInfo? info,
    @Default(false) bool isWorking,
    AppException? error,
  }) = _BackupState;

  const BackupState._();

  bool get isLoading => status.isLoading;
}
