// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/fine/data/fine_local_data_source.dart';
import 'package:khulla/features/circulation/shared/data/circulation_policy.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:uuid/uuid.dart';

/// Fine-row writes for returns and the desk ledger.
///
/// Transaction-scoped: constructed with the same [AppDatabase] the caller
/// runs its transaction on. Totals stay on [FineLocalDataSource]; views are
/// reloaded through it.
class CirculationFineWrites {
  CirculationFineWrites(this._db, this._policy);

  final AppDatabase _db;
  final CirculationPolicy _policy;

  static const Uuid _uuid = Uuid();
  static const String _source = 'CirculationFineWrites';

  Future<void> insertOverdueFine({
    required String memberId,
    required String loanId,
    required Money amount,
  }) => guardDatabase(
    () async {
      final now = DateTime.now();
      await _db
          .into(_db.fines)
          .insert(
            FinesCompanion.insert(
              id: _uuid.v4(),
              memberId: memberId,
              loanId: Value(loanId),
              reason: FineReason.overdue,
              assessed: amount,
              raisedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
    },
    source: '$_source.insertOverdueFine',
  );

  /// Collect and waive share one body; [waive] picks the settled column.
  Future<void> settleFine({required String id, required bool waive}) =>
      guardDatabase(
        () async {
          final row = await (_db.select(
            _db.fines,
          )..where((fine) => fine.id.equals(id))).getSingleOrNull();
          if (row == null) {
            throw const NotFoundException('That fine was not found.');
          }
          final outstanding = row.assessed - row.paid - row.waived;
          if (!outstanding.isPositive) {
            throw const ConflictException('That fine is already settled.');
          }
          final now = DateTime.now();
          await (_db.update(
            _db.fines,
          )..where((fine) => fine.id.equals(id))).write(
            waive
                ? FinesCompanion(
                    waived: Value(row.waived + outstanding),
                    settledAt: Value(now),
                    updatedAt: Value(now),
                  )
                : FinesCompanion(
                    paid: Value(row.paid + outstanding),
                    settledAt: Value(now),
                    updatedAt: Value(now),
                  ),
          );
        },
        source: '$_source.settleFine',
      );

  /// One-off hand-assessed fine; returns the new id for a view reload.
  Future<String> chargeManualFine({
    required String memberId,
    required FineReason reason,
    required Money amount,
    String? note,
  }) => guardDatabase(
    () async {
      if (!amount.isPositive) {
        throw const ConflictException(
          'A charged fine must be more than zero.',
        );
      }
      final memberRow = await (_db.select(
        _db.members,
      )..where((member) => member.id.equals(memberId))).getSingleOrNull();
      if (memberRow == null) {
        throw const NotFoundException('That member was not found.');
      }
      _policy.rejectArchivedMember(memberRow.archivedAt);

      final now = DateTime.now();
      final id = _uuid.v4();
      await _db
          .into(_db.fines)
          .insert(
            FinesCompanion.insert(
              id: id,
              memberId: memberId,
              reason: reason,
              assessed: amount,
              raisedAt: now,
              createdAt: now,
              updatedAt: now,
              note: Value(note),
            ),
          );
      return id;
    },
    source: '$_source.chargeManualFine',
  );
}
