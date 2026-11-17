// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/updates/domain/models/update_channel.dart';
import 'package:khulla/features/updates/domain/models/update_release.dart';
import 'package:khulla/features/updates/presentation/cubit/update_status.dart';

part 'update_state.freezed.dart';

@freezed
abstract class UpdateState with _$UpdateState {
  const factory UpdateState({
    required UpdateChannel channel,
    @Default(UpdateStatus.idle) UpdateStatus status,
    @Default(true) bool automaticChecks,

    /// The running version, once the dialog has asked for it.
    String? runningVersion,

    /// The newer release, while there is one.
    UpdateRelease? release,

    /// 0.0-1.0 while [UpdateStatus.downloading].
    @Default(0) double progress,

    /// The checked installer, once downloaded.
    String? installerPath,
    AppException? error,
  }) = _UpdateState;

  const UpdateState._();

  /// Whether a newer version is known - what puts the dot on the account
  /// chip.
  bool get hasUpdate => release != null;

  /// Whether a step is running that a second tap must not start again.
  bool get isBusy => switch (status) {
    UpdateStatus.checking ||
    UpdateStatus.downloading ||
    UpdateStatus.installing => true,
    _ => false,
  };
}
