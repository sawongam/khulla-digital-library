// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/circulation/shared/domain/fine_status.dart';

part 'fine.freezed.dart';

/// One charge against a member.
@freezed
abstract class Fine with _$Fine {
  const factory Fine({
    required String id,
    required String memberId,
    required FineReason reason,
    required Money assessed,
    required Money paid,
    required Money waived,
    required DateTime raisedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? loanId,
    String? memberName,
    String? titleName,
    DateTime? settledAt,
    String? note,
  }) = _Fine;

  const Fine._();

  Money get outstanding => assessed - paid - waived;

  FineStatus get status {
    if (outstanding.isPositive) return FineStatus.unpaid;
    if (waived.isPositive) return FineStatus.waived;
    return FineStatus.paid;
  }

  String get raisedOn => AppDateFormat.format(raisedAt);
}
