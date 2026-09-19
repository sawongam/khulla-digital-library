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

  Future<Copy> insertCopy({
    required Copy copy,
    String? barcodeOverride,
  });

  Future<Copy> updateCopy(Copy copy);

  Future<void> archiveCopy(String id, DateTime archivedAt);
}
