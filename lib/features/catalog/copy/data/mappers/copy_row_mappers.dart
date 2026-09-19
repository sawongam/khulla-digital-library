// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/catalog/copy/data/copy_local_data_source.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';

/// Maps [CopyRow] to [Copy] and back for drift writes.
///
/// Title name, borrower and due date come from joins in [CopyLocalDataSource].
extension CopyRowMapper on CopyRow {
  Copy toDomain({
    required String titleName,
    String? borrower,
    DateTime? dueAt,
  }) => Copy(
    id: id,
    barcode: barcode,
    titleId: titleId,
    titleName: titleName,
    shelf: shelf ?? '',
    status: status,
    acquiredAt: acquiredAt,
    notes: notes,
    archivedAt: archivedAt,
    borrower: borrower,
    dueAt: dueAt,
  );
}

extension CopyDomainMapper on Copy {
  CopiesCompanion toCompanion({
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => CopiesCompanion(
    id: Value(id),
    titleId: Value(titleId),
    barcode: Value(barcode),
    shelf: Value(shelf.isEmpty ? null : shelf),
    status: Value(status),
    acquiredAt: Value(acquiredAt),
    notes: Value(notes),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    archivedAt: Value(archivedAt),
  );
}
