// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/label/domain/models/label_queue_entry.dart';
import 'package:khulla/features/catalog/label/domain/models/label_size.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'label_state.freezed.dart';

/// The label desk: the queued stickers, the layout, and the library name.
///
/// [status] tracks the library-profile read only — the queue itself is local
/// state, so scanning never spins the screen. The preview reads [libraryName]
/// when [includeLibrary] is on.
@freezed
abstract class LabelState with _$LabelState {
  const factory LabelState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(<LabelQueueEntry>[]) List<LabelQueueEntry> queue,
    @Default(LabelSize.medium) LabelSize size,
    @Default(true) bool includeTitle,
    @Default(true) bool includeAuthor,
    @Default(true) bool includeShelf,
    @Default(false) bool includeLibrary,
    String? libraryName,
    @Default(false) bool isPrinting,
    AppException? error,
  }) = _LabelState;

  const LabelState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;

  int get labelCount => queue.fold(0, (total, entry) => total + entry.count);
}
