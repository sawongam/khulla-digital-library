// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// What happened at the desk: one line of the activity table.
///
/// A stand-in until circulation records loans. The kind is an enum rather
/// than a label so the row can pick its own glyph and tone without the
/// placeholder deciding how the table looks.
enum DashboardActivityKind { borrow, returned, reserved, fine }

/// One row of the dashboard's activity table.
class DashboardActivityEntry {
  const DashboardActivityEntry({
    required this.kind,
    required this.item,
    required this.itemCode,
    required this.member,
    required this.memberCode,
    required this.when,
    required this.due,
    required this.tone,
  });

  /// What was done.
  final DashboardActivityKind kind;

  /// The title involved.
  final String item;

  /// Its accession or barcode number.
  final String itemCode;

  /// Who did it.
  final String member;

  /// Their card number.
  final String memberCode;

  /// When, already formatted.
  final String when;

  /// The due date, already formatted, or null where the action has none.
  final String? due;

  /// The standing to paint the row's badge with.
  final AppStatusTone tone;

  /// The member's initials, for the row avatar.
  String get memberInitials {
    final words = member.trim().split(RegExp(r'\s+'));
    final head = words.first.isEmpty ? '' : words.first.substring(0, 1);
    final tail = words.length > 1 ? words.last.substring(0, 1) : '';
    return '$head$tail'.toUpperCase();
  }
}
