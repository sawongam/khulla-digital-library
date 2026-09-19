// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// One row of a "most borrowed" or "most active" list.
///
/// The figure is a string because the two lists count different things - a
/// loan tally and a member's borrow count - and both arrive already
/// formatted for the locale.
class DashboardRankedEntry {
  const DashboardRankedEntry({
    required this.name,
    required this.detail,
    required this.figure,
  });

  /// The title or the member.
  final String name;

  /// The supporting line - an author, a card number.
  final String detail;

  /// The tally, already formatted.
  final String figure;

  /// The leading tile's two letters.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    final head = words.first.isEmpty ? '' : words.first.substring(0, 1);
    final tail = words.length > 1 ? words.last.substring(0, 1) : '';
    return '$head$tail'.toUpperCase();
  }
}
