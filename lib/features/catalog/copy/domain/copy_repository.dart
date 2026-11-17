// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy_query.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';

/// Physical copies: search, add to a title, resolve by barcode.
///
/// [addCopy] assigns ids and defaults new rows to [CopyStatus.available];
/// barcodes can be left blank for the desk to assign later.
abstract interface class CopyRepository {
  Future<CopyListResult> findCopies(CopyQuery query);

  Future<List<Copy>> findCopiesByTitleId(String titleId);

  Future<Copy?> findCopyByBarcode(String barcode);

  Future<Copy?> findCopy(String id);

  Future<Copy> addCopy({
    required String titleId,
    required String titleName,
    String? shelf,
    String? barcode,
    String? notes,
  });

  /// Changes a copy's barcode, shelf and notes. The barcode must be set and
  /// not held by another copy, archived or not.
  Future<Copy> updateCopyDetails(
    String id, {
    required String barcode,
    required String shelf,
    String? notes,
  });

  Future<void> archiveCopy(String id);

  /// Brings an archived copy back. Refuses while its title is archived.
  Future<void> restoreCopy(String id);

  /// Updates standing. Refuses when the copy is on loan.
  Future<Copy> updateCopyStatus(
    String id, {
    required CopyStatus status,
  });
}
