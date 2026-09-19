// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';

/// Single-copy status writes shared by the loan and hold-queue helpers.
///
/// Free function on purpose: both helpers need it, and it must run inside
/// the caller's transaction - pass the same [AppDatabase] the transaction
/// runs on.
Future<void> setCopyStatus(
  AppDatabase db,
  String copyId,
  CopyStatus status,
) => guardDatabase(
  () async {
    await (db.update(
      db.copies,
    )..where((copy) => copy.id.equals(copyId))).write(
      CopiesCompanion(status: Value(status), updatedAt: Value(DateTime.now())),
    );
  },
  source: 'CirculationCopies.setCopyStatus',
);
