// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation_query.dart';

/// Read-side hold queries and queue helpers for checkout/return.
abstract interface class ReservationLocalDataSource {
  Future<ReservationListResult> findReservations(ReservationQuery query);

  Future<Reservation?> findReservationById(String id);

  Future<Reservation?> findActiveHoldForMemberOnTitle({
    required String memberId,
    required String titleId,
  });

  Future<Reservation?> findFirstWaitingHoldForTitle(String titleId);

  Future<int> countActiveHoldsForMember(String memberId);

  Future<bool> hasEarlierWaitingHold({
    required String titleId,
    required String memberId,
  });
}
