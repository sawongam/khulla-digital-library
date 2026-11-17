// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/models/member.dart';

/// A member-form field the library may switch off.
///
/// Name, barcode and member type are always asked for and are not listed.
/// [key] is what the settings row stores, so it is frozen: renaming a value
/// here must not change its key.
enum MemberOptionalField {
  grade('grade'),
  gender('gender'),
  dateOfBirth('dateOfBirth'),
  bloodGroup('bloodGroup'),
  email('email'),
  phone('phone'),
  address('address'),
  municipality('municipality'),
  occupation('occupation'),
  institution('institution'),
  idVerification('idVerification'),
  emergencyContact('emergencyContact'),
  guardian('guardian'),
  notes('notes'),
  sendNotices('sendNotices');

  MemberOptionalField(this.key);

  /// The stable text stored in `library_settings.hidden_member_fields`.
  final String key;

  /// Reads the stored comma-separated keys; unknown keys are ignored.
  static Set<MemberOptionalField> parseHidden(String stored) {
    final keys = stored
        .split(',')
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet();
    return {
      for (final field in values)
        if (keys.contains(field.key)) field,
    };
  }

  /// Whether [member] already holds a value for this field.
  ///
  /// The form keeps such a field visible even when the library hides it, so a
  /// stored value is never silently out of sight. The notices switch counts
  /// only when it differs from its default (on).
  bool isFilledOn(Member member) => switch (this) {
    grade => _has(member.grade),
    gender => member.gender != null,
    dateOfBirth => member.dateOfBirth != null,
    bloodGroup => member.bloodGroup != null,
    email => _has(member.email),
    phone => _has(member.phone),
    address => _has(member.address),
    municipality => _has(member.municipality),
    occupation => _has(member.occupation),
    institution => _has(member.institution),
    idVerification => _has(member.idVerification),
    emergencyContact =>
      _has(member.emergencyContactName) || _has(member.emergencyContactPhone),
    guardian => _has(member.guardian),
    notes => _has(member.notes),
    sendNotices => !member.sendNotices,
  };

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;

  /// The inverse of [parseHidden], in declaration order.
  static String encodeHidden(Set<MemberOptionalField> fields) => [
    for (final field in values)
      if (fields.contains(field)) field.key,
  ].join(',');
}
