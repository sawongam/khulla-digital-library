// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/members/domain/member_status.dart';

part 'member.freezed.dart';

/// One borrower on the register.
@freezed
abstract class Member with _$Member {
  const factory Member({
    required String id,
    required String fullName,
    required String barcode,
    required String memberTypeId,
    required String memberTypeName,
    required DateTime joinedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int loansOut,
    required int overdueLoans,
    required Money finesOwed,
    required int borrowedAllTime,
    String? memberTypeCode,
    @Default(true) bool sendNotices,
    Gender? gender,
    DateTime? dateOfBirth,
    BloodGroup? bloodGroup,
    String? email,
    String? phone,
    String? address,
    String? municipality,
    String? occupation,
    String? institution,
    String? idVerification,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? guardian,
    String? notes,
    DateTime? expiresAt,
    DateTime? suspendedAt,
    String? suspensionReason,
    DateTime? archivedAt,
  }) = _Member;

  const Member._();

  bool get isArchived => archivedAt != null;

  String get name => fullName;

  String get joined => AppDateFormat.format(joinedAt);

  String get expires =>
      expiresAt == null ? '' : AppDateFormat.format(expiresAt!);

  MemberStatus get status {
    if (suspendedAt != null) return MemberStatus.suspended;
    if (expiresAt == null) return MemberStatus.active;
    final today = DateTime.now();
    final expiry = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day);
    final now = DateTime(today.year, today.month, today.day);
    if (now.isAfter(expiry)) return MemberStatus.expired;
    final daysLeft = expiry.difference(now).inDays;
    if (daysLeft <= 30) return MemberStatus.expiring;
    return MemberStatus.active;
  }

  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    final first = words.first;
    final last = words.length > 1 ? words.last : '';
    final head = first.isEmpty ? '' : first.substring(0, 1);
    final tail = last.isEmpty
        ? (first.length > 1 ? first.substring(1, 2) : '')
        : last.substring(0, 1);
    return '$head$tail'.toUpperCase();
  }
}
