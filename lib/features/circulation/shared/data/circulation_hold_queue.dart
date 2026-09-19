// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/converters/date_only_converter.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/reservation/data/reservation_local_data_source.dart';
import 'package:khulla/features/circulation/shared/data/circulation_copies.dart';
import 'package:khulla/features/circulation/shared/data/circulation_policy.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';
import 'package:uuid/uuid.dart';

/// Hold-queue writes: placing, fulfilling, cancelling, staffing and expiring.
///
/// Transaction-scoped: constructed with the same [AppDatabase] the caller
/// runs its transaction on, so every write joins that transaction. Queue
/// views are reloaded through [ReservationLocalDataSource].
class CirculationHoldQueue {
  CirculationHoldQueue(this._db, this._policy);

  final AppDatabase _db;
  final CirculationPolicy _policy;

  static const Uuid _uuid = Uuid();
  static const DateOnlyConverter _dates = DateOnlyConverter();
  static const String _source = 'CirculationHoldQueue';

  /// Inserts a waiting hold that already passed rule checks; returns its id.
  Future<String> insertWaitingHold({
    required String memberId,
    required String titleId,
  }) => guardDatabase(
    () async {
      final now = DateTime.now();
      final id = _uuid.v4();
      await _db
          .into(_db.reservations)
          .insert(
            ReservationsCompanion.insert(
              id: id,
              titleId: titleId,
              memberId: memberId,
              placedAt: now,
              status: ReservationStatus.waiting,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return id;
    },
    source: '$_source.insertWaitingHold',
  );

  /// Closes the member's open hold on a title as fulfilled on checkout.
  Future<void> fulfillMemberHold({
    required String memberId,
    required String titleId,
  }) => guardDatabase(
    () async {
      final memberHold =
          await (_db.select(_db.reservations)..where(
                (hold) =>
                    hold.titleId.equals(titleId) &
                    hold.memberId.equals(memberId) &
                    hold.closedAt.isNull(),
              ))
              .getSingleOrNull();
      if (memberHold == null) return;
      final now = DateTime.now();
      await (_db.update(
        _db.reservations,
      )..where((hold) => hold.id.equals(memberHold.id))).write(
        ReservationsCompanion(
          status: const Value(ReservationStatus.fulfilled),
          closedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    },
    source: '$_source.fulfillMemberHold',
  );

  Future<void> cancelOpenHold(String reservationId) => guardDatabase(
    () async {
      final now = DateTime.now();
      final hold =
          await (_db.select(_db.reservations)..where(
                (row) => row.id.equals(reservationId) & row.closedAt.isNull(),
              ))
              .getSingleOrNull();
      if (hold == null) {
        throw const NotFoundException('That hold was not found.');
      }

      await (_db.update(
        _db.reservations,
      )..where((row) => row.id.equals(reservationId))).write(
        ReservationsCompanion(
          status: const Value(ReservationStatus.cancelled),
          closedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      if (hold.readyCopyId != null) {
        await setCopyStatus(_db, hold.readyCopyId!, CopyStatus.available);
        await promoteNextWaiting(
          titleId: hold.titleId,
          copyId: hold.readyCopyId!,
        );
      }
    },
    source: '$_source.cancelOpenHold',
  );

  /// Assigns the oldest available copy and moves a waiting hold to ready.
  /// Returns the id for a view reload.
  Future<String> markHoldReady(String reservationId) => guardDatabase(
    () async {
      final now = DateTime.now();
      final today = dateOnly(now);

      final hold =
          await (_db.select(_db.reservations)..where(
                (row) => row.id.equals(reservationId) & row.closedAt.isNull(),
              ))
              .getSingleOrNull();
      if (hold == null) {
        throw const NotFoundException('That hold was not found.');
      }
      if (hold.status != ReservationStatus.waiting) {
        throw const ConflictException(
          'Only waiting holds can be marked ready for pickup.',
        );
      }

      final copyRow =
          await (_db.select(_db.copies)
                ..where(
                  (copy) =>
                      copy.titleId.equals(hold.titleId) &
                      copy.archivedAt.isNull() &
                      copy.status.equalsValue(CopyStatus.available),
                )
                ..orderBy([(copy) => OrderingTerm(expression: copy.barcode)])
                ..limit(1))
              .getSingleOrNull();
      if (copyRow == null) {
        throw const ConflictException(
          'No available copy to assign to this hold.',
        );
      }

      final holdShelfDays = await _policy.loadHoldShelfDays();
      final expiresAt = addCalendarDays(today, holdShelfDays);

      await (_db.update(
        _db.reservations,
      )..where((row) => row.id.equals(reservationId))).write(
        ReservationsCompanion(
          status: const Value(ReservationStatus.ready),
          readyCopyId: Value(copyRow.id),
          readyAt: Value(now),
          expiresAt: Value(expiresAt),
          updatedAt: Value(now),
        ),
      );
      await setCopyStatus(_db, copyRow.id, CopyStatus.reserved);
      return reservationId;
    },
    source: '$_source.markHoldReady',
  );

  Future<void> expireStaleReady() => guardDatabase(
    () async {
      final now = DateTime.now();
      final today = dateOnly(now);

      final stale =
          await (_db.select(_db.reservations)..where(
                (hold) =>
                    hold.closedAt.isNull() &
                    hold.status.equalsValue(ReservationStatus.ready) &
                    hold.expiresAt.isSmallerThanValue(_dates.toSql(today)),
              ))
              .get();

      for (final hold in stale) {
        await (_db.update(
          _db.reservations,
        )..where((row) => row.id.equals(hold.id))).write(
          ReservationsCompanion(
            status: const Value(ReservationStatus.expired),
            closedAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        if (hold.readyCopyId != null) {
          await setCopyStatus(_db, hold.readyCopyId!, CopyStatus.available);
          await promoteNextWaiting(
            titleId: hold.titleId,
            copyId: hold.readyCopyId!,
          );
        }
      }
    },
    source: '$_source.expireStaleReady',
  );

  /// Moves the earliest waiting hold onto [copyId]; no-op when the queue is
  /// empty - the caller already released the copy.
  Future<void> promoteNextWaiting({
    required String titleId,
    required String copyId,
  }) => guardDatabase(
    () => _promoteNextWaiting(titleId: titleId, copyId: copyId),
    source: '$_source.promoteNextWaiting',
  );

  /// Return path: first waiting hold takes the copy, otherwise the copy goes
  /// back to available.
  Future<void> promoteOrRelease({
    required String copyId,
    required String titleId,
  }) => guardDatabase(
    () async {
      final nextHold = await _nextWaitingHold(titleId);
      if (nextHold == null) {
        await setCopyStatus(_db, copyId, CopyStatus.available);
        return;
      }
      await _promoteNextWaiting(titleId: titleId, copyId: copyId);
    },
    source: '$_source.promoteOrRelease',
  );

  Future<int> countWaitingHolds(String titleId) => guardDatabase(
    () {
      final count = _db.reservations.id.count(
        filter:
            _db.reservations.titleId.equals(titleId) &
            _db.reservations.closedAt.isNull() &
            _db.reservations.status.equalsValue(ReservationStatus.waiting),
      );
      return (_db.selectOnly(
        _db.reservations,
      )..addColumns([count])).getSingle().then((row) => row.read(count) ?? 0);
    },
    source: '$_source.countWaitingHolds',
  );

  /// Ready hold currently sitting on [copyId], for the reserved-copy check.
  Future<ReservationRow?> findReadyHoldForCopy(String copyId) => guardDatabase(
    () =>
        (_db.select(_db.reservations)..where(
              (hold) =>
                  hold.readyCopyId.equals(copyId) &
                  hold.closedAt.isNull() &
                  hold.status.equalsValue(ReservationStatus.ready),
            ))
            .getSingleOrNull(),
    source: '$_source.findReadyHoldForCopy',
  );

  Future<void> _promoteNextWaiting({
    required String titleId,
    required String copyId,
  }) async {
    final nextHold = await _nextWaitingHold(titleId);
    if (nextHold == null) return;

    final now = DateTime.now();
    final holdShelfDays = await _policy.loadHoldShelfDays();
    final expiresAt = addCalendarDays(dateOnly(now), holdShelfDays);
    await (_db.update(
      _db.reservations,
    )..where((hold) => hold.id.equals(nextHold.id))).write(
      ReservationsCompanion(
        status: const Value(ReservationStatus.ready),
        readyCopyId: Value(copyId),
        readyAt: Value(now),
        expiresAt: Value(expiresAt),
        updatedAt: Value(now),
      ),
    );
    await setCopyStatus(_db, copyId, CopyStatus.reserved);
  }

  Future<ReservationRow?> _nextWaitingHold(String titleId) =>
      (_db.select(_db.reservations)
            ..where(
              (hold) =>
                  hold.titleId.equals(titleId) &
                  hold.closedAt.isNull() &
                  hold.status.equalsValue(ReservationStatus.waiting),
            )
            ..orderBy([(hold) => OrderingTerm(expression: hold.placedAt)])
            ..limit(1))
          .getSingleOrNull();
}
