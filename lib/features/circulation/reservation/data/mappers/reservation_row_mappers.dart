// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';

/// Maps [ReservationRow] to [Reservation] and back for drift writes.
extension ReservationRowMapper on ReservationRow {
  Reservation toDomain({
    String? titleName,
    String? memberName,
    int queuePosition = 0,
  }) => Reservation(
    id: id,
    titleId: titleId,
    memberId: memberId,
    placedAt: placedAt,
    status: status,
    readyCopyId: readyCopyId,
    readyAt: readyAt,
    expiresAt: expiresAt,
    closedAt: closedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    titleName: titleName,
    memberName: memberName,
    queuePosition: queuePosition,
  );
}

extension ReservationDomainMapper on Reservation {
  ReservationsCompanion toCompanion() => ReservationsCompanion(
    id: Value(id),
    titleId: Value(titleId),
    memberId: Value(memberId),
    placedAt: Value(placedAt),
    status: Value(status),
    readyCopyId: Value(readyCopyId),
    readyAt: Value(readyAt),
    expiresAt: Value(expiresAt),
    closedAt: Value(closedAt),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}
