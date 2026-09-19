// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';

part 'label_queue_entry.freezed.dart';

/// One copy waiting for its sticker, and how many of that sticker to print.
///
/// A copy needs a second label often enough — one peels off, one goes inside
/// the cover — that the queue counts labels rather than assuming one each.
/// [author] is resolved from the title at queue time so the preview never
/// queries while it draws.
@freezed
abstract class LabelQueueEntry with _$LabelQueueEntry {
  const factory LabelQueueEntry({
    required Copy copy,
    String? author,
    @Default(1) int count,
  }) = _LabelQueueEntry;

  const LabelQueueEntry._();

  /// The same entry with [count] replaced, floored at one.
  LabelQueueEntry withCount(int next) => copyWith(count: next < 1 ? 1 : next);
}
