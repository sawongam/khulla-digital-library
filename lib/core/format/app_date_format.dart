// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:intl/intl.dart';

/// How calendar dates are shown on screen.
///
/// Amounts go through money formatting; dates had no equivalent until
/// persistence landed.
abstract final class AppDateFormat {
  static final DateFormat display = DateFormat('d MMM y');

  static String format(DateTime date) => display.format(date);
}
