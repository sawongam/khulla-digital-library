// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/money/money.dart';

part 'member_type.freezed.dart';

/// An editable member category with optional rule overrides.
@freezed
abstract class MemberType with _$MemberType {
  const factory MemberType({
    required String id,
    required String name,
    required int sortOrder,
    required bool isSystem,
    required DateTime createdAt,
    String? code,
    DateTime? archivedAt,
    int? loanPeriodDays,
    int? borrowingLimit,
    int? renewalLimit,
    int? renewalPeriodDays,
    Money? finePerDay,
    int? graceDays,
    Money? maximumFinePerCopy,
    Money? maxOutstandingFine,
    int? membershipDurationMonths,
    int? reservationLimit,
  }) = _MemberType;

  const MemberType._();

  bool get isArchived => archivedAt != null;
}
