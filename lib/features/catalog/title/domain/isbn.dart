// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// Reduces typed text to a bare ISBN-10 or ISBN-13, or null when it is not one.
///
/// Spaces and hyphens are dropped; an ISBN-10 may end in `X`. The check digit
/// is verified, so a mistyped digit is caught here instead of coming back
/// from the network as "not found".
String? normalizeIsbn(String input) {
  final text = input.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  if (RegExp(r'^\d{13}$').hasMatch(text)) {
    var sum = 0;
    for (var i = 0; i < 13; i++) {
      sum += int.parse(text[i]) * (i.isEven ? 1 : 3);
    }
    return sum % 10 == 0 ? text : null;
  }
  if (RegExp(r'^\d{9}[\dX]$').hasMatch(text)) {
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final digit = text[i] == 'X' ? 10 : int.parse(text[i]);
      sum += digit * (10 - i);
    }
    return sum % 11 == 0 ? text : null;
  }
  return null;
}
