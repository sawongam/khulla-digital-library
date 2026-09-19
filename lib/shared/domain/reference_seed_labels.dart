// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// English seed labels matching `app_en.arb` — bootstrap has no l10n context.
String seedFormatName(String code) => switch (code) {
  'book' => 'Book',
  'journal' => 'Journal',
  'other' => 'Other',
  _ => code,
};

String seedMemberTypeName(String code) => switch (code) {
  'student' => 'Student',
  'teacher' => 'Teacher',
  'public' => 'Public',
  'child' => 'Child',
  'other' => 'Other',
  _ => code,
};
