// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';

part 'staff_member.freezed.dart';

/// One staff account: who they are and what they may do.
///
/// Deliberately carries no password hash. A screen never needs one, and a
/// model that holds it is a model that eventually gets logged, put in a state
/// object, or dumped into an export. Verification takes place behind
/// `StaffRepository`, which reads the hash and never lets it out — see
/// `StaffCredentials`.
@freezed
abstract class StaffMember with _$StaffMember {
  const factory StaffMember({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    required UserStatus status,
    required DateTime createdAt,
    String? barcode,
  }) = _StaffMember;

  const StaffMember._();

  /// Whether this account may sign in today.
  bool get canSignIn => status == UserStatus.active;

  /// Whether this account holds every permission — the account first-run
  /// setup creates.
  bool get isAdministrator => role == UserRole.administrator;

  /// The circle's two letters.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    final first = words.first;
    final last = words.length > 1 ? words.last : '';
    final head = first.isEmpty ? '' : first.substring(0, 1);
    final tail = last.isEmpty
        ? (first.length > 1 ? first.substring(1, 2) : '')
        : last.substring(0, 1);
    return '$head$tail'.toUpperCase();
  }
}
