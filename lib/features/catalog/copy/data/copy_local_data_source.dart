// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy_query.dart';

/// Drift access to `copies` and the open loan that fills borrower fields.
abstract interface class CopyLocalDataSource {
  Future<CopyListResult> findCopies(CopyQuery query);

  Future<List<Copy>> findCopiesByTitleId(String titleId);

  Future<Copy?> findCopyByBarcode(String barcode);

  Future<Copy?> findCopyById(String id);

  /// The copy that holds [barcode], archived or not - the unique index counts
  /// archived rows, so a clash can be with a copy that is out of sight.
  Future<Copy?> findCopyHoldingBarcode(String barcode);

  Future<Copy> insertCopy({
    required Copy copy,
    String? barcodeOverride,
  });

  Future<Copy> updateCopy(Copy copy);

  /// Changes a copy's barcode, shelf and notes. Throws a duplicate-record
  /// refusal naming the holder when the barcode belongs to another copy.
  Future<Copy> updateCopyDetails(
    String id, {
    required String barcode,
    required String shelf,
    String? notes,
  });

  Future<void> archiveCopy(String id, DateTime archivedAt);

  /// Clears `archived_at`. Refuses while the copy's title is archived.
  Future<void> restoreCopy(String id);
}
