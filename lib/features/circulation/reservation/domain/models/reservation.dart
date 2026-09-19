// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';

part 'reservation.freezed.dart';

/// One hold on a title - any copy can satisfy it.
@freezed
abstract class Reservation with _$Reservation {
  const factory Reservation({
    required String id,
    required String titleId,
    required String memberId,
    required DateTime placedAt,
    required ReservationStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? titleName,
    String? memberName,
    String? readyCopyId,
    DateTime? readyAt,
    DateTime? expiresAt,
    DateTime? closedAt,
    @Default(0) int queuePosition,
  }) = _Reservation;

  const Reservation._();

  bool get isActive => closedAt == null;

  String get placedOn => AppDateFormat.format(placedAt);

  String? get expiresOn =>
      expiresAt == null ? null : AppDateFormat.format(expiresAt!);
}
