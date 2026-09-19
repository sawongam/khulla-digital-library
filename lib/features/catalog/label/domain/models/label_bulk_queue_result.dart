// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';

part 'label_bulk_queue_result.freezed.dart';

/// The outcome of queueing a pasted list of barcodes: how many matched a
/// copy, and which ones matched nothing.
@freezed
abstract class LabelBulkQueueResult with _$LabelBulkQueueResult {
  const factory LabelBulkQueueResult({
    required int queuedCount,
    required List<String> notFound,
  }) = _LabelBulkQueueResult;

  const LabelBulkQueueResult._();

  /// Whether every barcode in the batch matched a copy.
  bool get isComplete => notFound.isEmpty;
}
